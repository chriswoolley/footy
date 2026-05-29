import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth, type AuthedRequest } from "../auth.js";
import { syncBootstrap, syncGameweek, plFixturesByDay } from "../fpl.js";
import {
  syncTeamsAndPlayers as syncWcTeamsAndPlayers,
  syncFixtures as syncWcFixtures,
  wipePremierLeagueData,
  fixturesByDay,
} from "../wc2026.js";
import { getBidMode, setBidMode, audit, type BidMode } from "../settings.js";
import { seedHistory } from "../seedHistory.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");

router.use(requireAuth);

router.get("/status", async (_req, res) => {
  const [mode, bootstrap, managers, pendingBids, players, snapshots] = await Promise.all([
    getBidMode(),
    prisma.syncState.findUnique({ where: { key: "bootstrap" } }),
    prisma.manager.count(),
    prisma.bid.count({ where: { resolved: false } }),
    prisma.player.count(),
    prisma.pointSnapshot.count(),
  ]);

  const lastLive = await prisma.syncState.findMany({
    where: { key: { startsWith: "live:" } },
    orderBy: { when: "desc" },
    take: 1,
  });

  res.json({
    mode,
    lastBootstrapSync: bootstrap?.value ?? null,
    lastLiveSync: lastLive[0]?.when ?? null,
    lastLiveGw: lastLive[0]?.key.replace("live:", "") ?? null,
    counts: {
      managers,
      players,
      snapshots,
      pendingBids,
    },
  });
});

router.post("/mode", async (req: AuthedRequest, res) => {
  const { mode } = req.body ?? {};
  if (mode !== "immediate" && mode !== "deferred") {
    return res.status(400).json({ error: "mode must be 'immediate' or 'deferred'" });
  }
  await setBidMode(mode as BidMode);
  await audit(`manager:${req.managerId}`, `set bid mode to ${mode}`);
  res.json({ ok: true, mode });
});

router.get("/pending-bids", async (_req, res) => {
  const bids = await prisma.bid.findMany({
    where: { resolved: false },
    include: {
      manager: { select: { id: true, teamName: true } },
      player: { include: { team: true } },
    },
    orderBy: [{ playerId: "asc" }, { amount: "desc" }],
  });
  res.json(
    bids.map((b) => ({
      id: b.id,
      managerId: b.managerId,
      managerTeam: b.manager.teamName,
      playerId: b.playerId,
      playerName: b.player.webName,
      playerTeam: b.player.team.name,
      playerTeamShort: b.player.team.shortName,
      position: b.player.position,
      amount: b.amount,
      placedAt: b.placedAt,
    })),
  );
});

// Resolve every pending bid. Highest amount per player wins; in case of a
// tie, earliest placement. Loser bids are marked resolved+won=false and get
// a PaperTalk "Outbid" entry.
router.post("/run-bids", async (req: AuthedRequest, res) => {
  const result = await prisma.$transaction(async (tx) => {
    const pending = await tx.bid.findMany({
      where: { resolved: false },
      orderBy: [{ amount: "desc" }, { placedAt: "asc" }],
      include: { player: { include: { team: true } } },
    });
    if (pending.length === 0) return { won: 0, lost: 0, skipped: 0 };

    // Group by player
    const byPlayer = new Map<number, typeof pending>();
    for (const b of pending) {
      const list = byPlayer.get(b.playerId) ?? [];
      list.push(b);
      byPlayer.set(b.playerId, list);
    }

    let won = 0;
    let lost = 0;
    let skipped = 0;

    for (const [playerId, bids] of byPlayer) {
      // Skip if already owned
      const owner = await tx.squadEntry.findFirst({
        where: { playerId, untilAt: FOREVER },
      });
      if (owner) {
        for (const b of bids) {
          await tx.bid.update({
            where: { id: b.id },
            data: { resolved: true, won: false },
          });
          await tx.paperTalk.create({
            data: {
              managerId: b.managerId,
              teamName: b.player.team.name,
              playerName: b.player.webName,
              reason: "Outbid (player already taken)",
              bid: b.amount,
            },
          });
          skipped++;
        }
        continue;
      }

      const winner = bids[0];
      const losers = bids.slice(1);

      // Re-check the winner's budget at resolution time (sells refund book
      // price, so include realised losses from past sales).
      const winnerEntries = await tx.squadEntry.findMany({
        where: { managerId: winner.managerId, untilAt: FOREVER },
      });
      const winnerSoldEntries = await tx.squadEntry.findMany({
        where: { managerId: winner.managerId, untilAt: { lt: FOREVER } },
        select: { bid: true, sellPrice: true },
      });
      const winnerRealisedLosses = winnerSoldEntries.reduce(
        (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
        0,
      );
      const winnerSpent =
        winnerEntries.reduce((s, e) => s + e.bid, 0) + winnerRealisedLosses;
      const BUDGET = Number(process.env.BUDGET ?? 75);
      const MAX_SQUAD = Number(process.env.MAX_SQUAD ?? 20);
      if (winnerSpent + winner.amount > BUDGET + 1e-9 || winnerEntries.length >= MAX_SQUAD) {
        // Winner can no longer afford — skip; second highest gets a shot if any
        await tx.bid.update({
          where: { id: winner.id },
          data: { resolved: true, won: false },
        });
        await tx.paperTalk.create({
          data: {
            managerId: winner.managerId,
            teamName: winner.player.team.name,
            playerName: winner.player.webName,
            reason: "Bid void — budget or squad full",
            bid: winner.amount,
          },
        });
        skipped++;
        // Cascade to next bidder
        for (const b of losers) {
          const otherEntries = await tx.squadEntry.findMany({
            where: { managerId: b.managerId, untilAt: FOREVER },
          });
          const otherSoldEntries = await tx.squadEntry.findMany({
            where: { managerId: b.managerId, untilAt: { lt: FOREVER } },
            select: { bid: true, sellPrice: true },
          });
          const otherRealisedLosses = otherSoldEntries.reduce(
            (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
            0,
          );
          const otherSpent =
            otherEntries.reduce((s, e) => s + e.bid, 0) + otherRealisedLosses;
          if (otherSpent + b.amount <= BUDGET + 1e-9 && otherEntries.length < MAX_SQUAD) {
            await tx.bid.update({
              where: { id: b.id },
              data: { resolved: true, won: true },
            });
            await tx.squadEntry.create({
              data: {
                managerId: b.managerId,
                playerId,
                bid: b.amount,
                untilAt: FOREVER,
              },
            });
            await tx.paperTalk.create({
              data: {
                managerId: b.managerId,
                teamName: b.player.team.name,
                playerName: b.player.webName,
                reason: "Signed",
                bid: b.amount,
              },
            });
            won++;
            // mark the rest as outbid
            for (const o of losers.filter((x) => x.id !== b.id)) {
              await tx.bid.update({
                where: { id: o.id },
                data: { resolved: true, won: false },
              });
              await tx.paperTalk.create({
                data: {
                  managerId: o.managerId,
                  teamName: o.player.team.name,
                  playerName: o.player.webName,
                  reason: "Outbid",
                  bid: o.amount,
                },
              });
              lost++;
            }
            break;
          }
        }
        continue;
      }

      // Award to highest bidder
      await tx.bid.update({
        where: { id: winner.id },
        data: { resolved: true, won: true },
      });
      await tx.squadEntry.create({
        data: {
          managerId: winner.managerId,
          playerId,
          bid: winner.amount,
          untilAt: FOREVER,
        },
      });
      await tx.paperTalk.create({
        data: {
          managerId: winner.managerId,
          teamName: winner.player.team.name,
          playerName: winner.player.webName,
          reason: "Signed",
          bid: winner.amount,
        },
      });
      won++;

      for (const b of losers) {
        await tx.bid.update({
          where: { id: b.id },
          data: { resolved: true, won: false },
        });
        await tx.paperTalk.create({
          data: {
            managerId: b.managerId,
            teamName: b.player.team.name,
            playerName: b.player.webName,
            reason: "Outbid",
            bid: b.amount,
          },
        });
        lost++;
      }
    }

    return { won, lost, skipped };
  });

  await audit(
    `manager:${req.managerId}`,
    `ran bid resolution: ${result.won} won, ${result.lost} outbid, ${result.skipped} skipped`,
  );
  res.json({ ok: true, ...result });
});

router.post("/sync", async (req: AuthedRequest, res) => {
  try {
    const { teams, players } = await syncWcTeamsAndPlayers();
    const fixtures = await syncWcFixtures();
    await audit(`manager:${req.managerId}`, `force-synced World Cup data`);
    res.json({ ok: true, teams, players, fixtures });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/sync-fpl", async (req: AuthedRequest, res) => {
  try {
    const data = await syncBootstrap();
    const current = data.events.find((e) => e.is_current) ?? data.events.find((e) => e.is_next);
    let liveGw: number | null = null;
    if (current) {
      await syncGameweek(current.id);
      liveGw = current.id;
    }
    await audit(`manager:${req.managerId}`, `force-synced FPL data (GW${liveGw ?? "?"})`);
    res.json({
      ok: true,
      teams: data.teams.length,
      players: data.elements.length,
      liveGw,
    });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/migrate-to-wc", async (req: AuthedRequest, res) => {
  try {
    await wipePremierLeagueData();
    const { teams, players } = await syncWcTeamsAndPlayers();
    const fixtures = await syncWcFixtures();
    await audit(
      `manager:${req.managerId}`,
      `migrated to World Cup data: ${teams} teams, ${players} players, ${fixtures} fixtures`,
    );
    res.json({ ok: true, teams, players, fixtures });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.get("/fixtures", async (_req, res) => {
  try {
    const teamCount = await prisma.team.count();
    // 20 teams ≈ PL; 48 ≈ WC. Fall back to WC if no teams are loaded.
    const grouped = teamCount === 20 ? await plFixturesByDay() : await fixturesByDay();
    res.json(grouped);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/reseed", async (req: AuthedRequest, res) => {
  try {
    const logLines: string[] = [];
    const result = await seedHistory((m) => logLines.push(m));
    await audit(`manager:${req.managerId}`, "reseeded historical demo data");
    res.json({ ok: true, ...result, log: logLines });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post("/clear-bids", async (req: AuthedRequest, res) => {
  const result = await prisma.bid.deleteMany({ where: { resolved: false } });
  await audit(`manager:${req.managerId}`, `cleared ${result.count} pending bids`);
  res.json({ ok: true, deleted: result.count });
});

router.get("/audit", async (_req, res) => {
  const items = await prisma.audit.findMany({
    orderBy: { when: "desc" },
    take: 100,
  });
  res.json(items);
});

router.get("/managers", async (_req, res) => {
  const managers = await prisma.manager.findMany({
    orderBy: { id: "asc" },
    select: {
      id: true,
      username: true,
      teamName: true,
      formation: true,
      createdAt: true,
      _count: {
        select: {
          squad: true,
          bids: true,
        },
      },
    },
  });
  res.json(
    managers.map((m) => ({
      id: m.id,
      username: m.username,
      teamName: m.teamName,
      formation: m.formation,
      createdAt: m.createdAt,
      squadCount: m._count.squad,
      bidCount: m._count.bids,
    })),
  );
});

router.delete("/managers/:id", async (req: AuthedRequest, res) => {
  const id = Number(req.params.id);
  if (id === req.managerId) {
    return res.status(400).json({ error: "cannot delete yourself" });
  }
  const target = await prisma.manager.findUnique({ where: { id } });
  if (!target) return res.status(404).json({ error: "manager not found" });

  await prisma.$transaction([
    prisma.paperTalk.deleteMany({ where: { managerId: id } }),
    prisma.bid.deleteMany({ where: { managerId: id } }),
    prisma.squadEntry.deleteMany({ where: { managerId: id } }),
    prisma.manager.delete({ where: { id } }),
  ]);
  await audit(`manager:${req.managerId}`, `deleted manager ${target.username} (${target.teamName})`);
  res.json({ ok: true });
});

const FOREVER_ISO = "9999-12-31T00:00:00.000Z";

// Transfer log: every SquadEntry, oldest first off the bottom. Includes the
// bid price (what they paid to join) and selling price (what they got back
// when the entry closed — currently equal to the bid amount since the budget
// frees the full bid on sell).
router.get("/transfers", async (_req, res) => {
  const entries = await prisma.squadEntry.findMany({
    orderBy: [{ fromAt: "desc" }, { id: "desc" }],
    take: 500,
    include: {
      manager: { select: { id: true, teamName: true } },
      player: { include: { team: { select: { shortName: true } } } },
    },
  });
  res.json(
    entries.map((e) => {
      const isActive = e.untilAt.toISOString() === FOREVER_ISO;
      return {
        id: e.id,
        managerId: e.manager.id,
        managerTeam: e.manager.teamName,
        playerId: e.playerId,
        playerName: e.player.webName,
        playerTeamShort: e.player.team.shortName,
        position: e.player.position,
        boughtAt: e.fromAt,
        bidPrice: e.bid,
        soldAt: isActive ? null : e.untilAt,
        // Real sell price: book at sale time. Falls back to bid if missing
        // (legacy rows from before sellPrice was tracked).
        sellPrice: isActive ? null : (e.sellPrice ?? e.bid),
        status: isActive ? "active" : "sold",
      };
    }),
  );
});

// Bidding log: every bid placed, including pending, won, and lost.
router.get("/bid-log", async (_req, res) => {
  const bids = await prisma.bid.findMany({
    orderBy: [{ placedAt: "desc" }, { id: "desc" }],
    take: 500,
    include: {
      manager: { select: { id: true, teamName: true } },
      player: { include: { team: { select: { shortName: true } } } },
    },
  });
  res.json(
    bids.map((b) => ({
      id: b.id,
      managerId: b.manager.id,
      managerTeam: b.manager.teamName,
      playerId: b.playerId,
      playerName: b.player.webName,
      playerTeamShort: b.player.team.shortName,
      position: b.player.position,
      amount: b.amount,
      placedAt: b.placedAt,
      status: !b.resolved ? "pending" : b.won ? "won" : "lost",
    })),
  );
});

export default router;
