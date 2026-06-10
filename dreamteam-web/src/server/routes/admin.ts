import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth, requireAdmin, type AuthedRequest } from "../auth.js";
import { syncBootstrap, syncGameweek, plFixturesByDay } from "../fpl.js";
import {
  syncAll as syncFifaAll,
  wipePlayerData,
  fixturesByDay,
} from "../fifaFantasy.js";
import { audit } from "../settings.js";
import { seedHistory } from "../seedHistory.js";
import { backupNow } from "../backup.js";
import { resolvePendingBids } from "../bidding.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");

router.use(requireAuth, requireAdmin);

router.get("/status", async (_req, res) => {
  const [bootstrap, managers, pendingBids, players, snapshots] = await Promise.all([
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

// Trigger an immediate DB snapshot (the daily backup runs automatically too).
router.post("/backup", async (req: AuthedRequest, res) => {
  try {
    const file = await backupNow();
    await audit(`manager:${req.managerId}`, `ran manual backup`);
    res.json({ ok: true, file: file.split("/").pop() });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
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
  const result = await resolvePendingBids();

  await audit(
    `manager:${req.managerId}`,
    `ran bid resolution: ${result.won} won, ${result.lost} outbid, ${result.skipped} skipped`,
  );
  res.json({ ok: true, ...result });
});

router.post("/sync", async (req: AuthedRequest, res) => {
  try {
    const result = await syncFifaAll();
    await audit(`manager:${req.managerId}`, `force-synced FIFA fantasy data`);
    res.json({ ok: true, ...result });
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
    await wipePlayerData();
    const result = await syncFifaAll();
    await audit(
      `manager:${req.managerId}`,
      `migrated to FIFA fantasy data: ${result.teams} teams, ${result.players} players, ${result.fixtures} fixtures`,
    );
    res.json({ ok: true, ...result });
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
