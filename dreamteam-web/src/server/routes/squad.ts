import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth, type AuthedRequest } from "../auth.js";
import { getBidMode } from "../settings.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 75);

router.use(requireAuth);

// Team-selection changes (play / bench) don't apply immediately — they
// queue up in PendingChange and commit at the next 01:00 UTC, matching the
// daily bid resolution deadline. The user sees them in a pending list on
// the Squad page and can cancel before the cutoff.
function nextDeadline(now: Date): Date {
  const next = new Date(now);
  next.setUTCHours(1, 0, 0, 0);
  if (next <= now) next.setUTCDate(next.getUTCDate() + 1);
  return next;
}

// Apply any pending changes whose effectiveAt has passed for this manager.
// Called on every /api/squad fetch so the user's view is always up-to-date.
async function applyDuePending(managerId: number): Promise<number> {
  const now = new Date();
  const due = await prisma.pendingChange.findMany({
    where: { managerId, effectiveAt: { lte: now } },
    orderBy: { effectiveAt: "asc" },
  });
  if (due.length === 0) return 0;
  for (const c of due) {
    if (c.kind === "PLAY" && c.toSlot != null) {
      // Validate the slot for the manager's current formation.
      const manager = await prisma.manager.findUnique({ where: { id: managerId } });
      if (!manager) continue;
      const layout = manager.formation === "433" ? [1, 4, 3, 3] : [1, 4, 4, 2];
      const slotPositions: number[] = [];
      layout.forEach((count, posIdx) => {
        for (let i = 0; i < count; i++) slotPositions.push(posIdx + 1);
      });
      const requiredPos = slotPositions[c.toSlot];
      const entry = await prisma.squadEntry.findFirst({
        where: { managerId, playerId: c.playerId, untilAt: FOREVER },
        include: { player: true },
      });
      if (!entry || entry.player.position !== requiredPos) {
        // Squad changed since we queued — silently drop.
        await prisma.pendingChange.delete({ where: { id: c.id } });
        continue;
      }
      await prisma.squadEntry.updateMany({
        where: { managerId, formationSlot: c.toSlot, untilAt: FOREVER },
        data: { playing: false, formationSlot: null },
      });
      await prisma.squadEntry.update({
        where: { id: entry.id },
        data: { playing: true, formationSlot: c.toSlot },
      });
    } else if (c.kind === "BENCH") {
      await prisma.squadEntry.updateMany({
        where: { managerId, playerId: c.playerId, untilAt: FOREVER },
        data: { playing: false, formationSlot: null },
      });
    }
    await prisma.pendingChange.delete({ where: { id: c.id } });
  }
  return due.length;
}

router.get("/", async (req: AuthedRequest, res) => {
  // Apply any due pending changes before the manager sees their squad.
  await applyDuePending(req.managerId!);
  const [entries, soldEntries, bidMode] = await Promise.all([
    prisma.squadEntry.findMany({
      where: { managerId: req.managerId, untilAt: FOREVER },
      include: { player: { include: { team: true } } },
    }),
    prisma.squadEntry.findMany({
      where: { managerId: req.managerId, untilAt: { lt: FOREVER } },
      select: { bid: true, sellPrice: true },
    }),
    getBidMode(),
  ]);
  const activeSpent = entries.reduce((sum, e) => sum + e.bid, 0);
  // Realised losses on past sales: bid − sellPrice (or 0 if no sellPrice recorded).
  const realisedLosses = soldEntries.reduce(
    (sum, e) => sum + (e.bid - (e.sellPrice ?? e.bid)),
    0,
  );
  const spent = activeSpent + realisedLosses;
  res.json({
    budget: BUDGET,
    spent,
    balance: BUDGET - spent,
    bidMode,
    entries: entries.map((e) => ({
      id: e.id,
      playerId: e.playerId,
      name: e.player.webName,
      team: e.player.team.name,
      teamShort: e.player.team.shortName,
      position: e.player.position,
      price: e.player.nowCost / 10,
      points: e.player.totalPoints,
      bid: e.bid,
      playing: e.playing,
      formationSlot: e.formationSlot,
      photoUrl: e.player.photoCode
        ? `https://resources.premierleague.com/premierleague/photos/players/110x140/p${e.player.photoCode}.png`
        : null,
    })),
  });
});

router.post("/formation", async (req: AuthedRequest, res) => {
  const { formation } = req.body ?? {};
  if (formation !== "442" && formation !== "433") {
    return res.status(400).json({ error: "formation must be 442 or 433" });
  }
  const manager = await prisma.manager.findUnique({ where: { id: req.managerId } });
  if (!manager) return res.status(404).json({ error: "manager" });

  // No-op if the formation hasn't changed — clicking the already-active
  // button shouldn't dump the entire starting XI to the bench.
  if (manager.formation === formation) {
    return res.json({ ok: true, unchanged: true });
  }

  // Compute the new slot → required-position map.
  const layout = formation === "433" ? [1, 4, 3, 3] : [1, 4, 4, 2];
  const newSlotPos: number[] = [];
  layout.forEach((count, posIdx) => {
    for (let i = 0; i < count; i++) newSlotPos.push(posIdx + 1);
  });

  await prisma.manager.update({
    where: { id: req.managerId },
    data: { formation },
  });

  // Keep any current starter whose slot's required position still matches
  // their actual position under the new formation; bench the rest. (442↔433
  // shifts MID/FWD counts so usually 1 player needs replacing.)
  const starters = await prisma.squadEntry.findMany({
    where: { managerId: req.managerId, untilAt: FOREVER, playing: true },
    include: { player: { select: { position: true } } },
  });
  for (const s of starters) {
    if (s.formationSlot == null) continue;
    const required = newSlotPos[s.formationSlot];
    if (required !== s.player.position) {
      await prisma.squadEntry.update({
        where: { id: s.id },
        data: { playing: false, formationSlot: null },
      });
    }
  }
  res.json({ ok: true });
});

router.post("/play", async (req: AuthedRequest, res) => {
  const { playerId, slot } = req.body ?? {};
  if (typeof playerId !== "number" || typeof slot !== "number") {
    return res.status(400).json({ error: "playerId and slot required" });
  }
  const manager = await prisma.manager.findUnique({ where: { id: req.managerId } });
  if (!manager) return res.status(404).json({ error: "manager" });

  const layout = manager.formation === "433" ? [1, 4, 3, 3] : [1, 4, 4, 2];
  const slotPositions: number[] = [];
  layout.forEach((count, posIdx) => {
    for (let i = 0; i < count; i++) slotPositions.push(posIdx + 1);
  });
  if (slot < 0 || slot >= slotPositions.length) {
    return res.status(400).json({ error: "slot out of range" });
  }
  const requiredPos = slotPositions[slot];

  const entry = await prisma.squadEntry.findFirst({
    where: { managerId: req.managerId, playerId, untilAt: FOREVER },
    include: { player: true },
  });
  if (!entry) return res.status(404).json({ error: "player not in your squad" });
  if (entry.player.position !== requiredPos) {
    return res.status(400).json({ error: "wrong position for this slot" });
  }

  // Replace any existing pending PLAY for this player so the latest intent wins.
  await prisma.pendingChange.deleteMany({
    where: { managerId: req.managerId, playerId, kind: { in: ["PLAY", "BENCH"] } },
  });
  const effectiveAt = nextDeadline(new Date());
  const change = await prisma.pendingChange.create({
    data: {
      managerId: req.managerId!,
      kind: "PLAY",
      playerId,
      toSlot: slot,
      effectiveAt,
    },
  });
  res.json({ ok: true, pending: change });
});

router.post("/bench", async (req: AuthedRequest, res) => {
  const { playerId } = req.body ?? {};
  if (typeof playerId !== "number") return res.status(400).json({ error: "playerId required" });
  // Replace any existing pending change for this player.
  await prisma.pendingChange.deleteMany({
    where: { managerId: req.managerId, playerId, kind: { in: ["PLAY", "BENCH"] } },
  });
  const effectiveAt = nextDeadline(new Date());
  const change = await prisma.pendingChange.create({
    data: {
      managerId: req.managerId!,
      kind: "BENCH",
      playerId,
      effectiveAt,
    },
  });
  res.json({ ok: true, pending: change });
});

router.get("/pending", async (req: AuthedRequest, res) => {
  const rows = await prisma.pendingChange.findMany({
    where: { managerId: req.managerId },
    orderBy: { createdAt: "asc" },
  });
  if (rows.length === 0) return res.json([]);

  // Resolve the incoming player metadata for every change.
  const playerIds = new Set(rows.map((r) => r.playerId));
  // For PLAY changes we also need to look up whoever currently occupies the
  // target slot (i.e. who's being knocked off the XI).
  const playSlots = new Set<number>();
  for (const r of rows) {
    if (r.kind === "PLAY" && r.toSlot != null) playSlots.add(r.toSlot);
  }
  const slotOccupants = await prisma.squadEntry.findMany({
    where: {
      managerId: req.managerId,
      untilAt: FOREVER,
      playing: true,
      formationSlot: { in: Array.from(playSlots) },
    },
    select: { playerId: true, formationSlot: true },
  });
  for (const o of slotOccupants) playerIds.add(o.playerId);

  const players = await prisma.player.findMany({
    where: { id: { in: Array.from(playerIds) } },
    include: { team: true },
  });
  const byId = new Map(players.map((p) => [p.id, p]));
  const occupantBySlot = new Map(slotOccupants.map((o) => [o.formationSlot, o.playerId]));

  function photo(playerId: number): string | null {
    const p = byId.get(playerId);
    return p?.photoCode
      ? `https://resources.premierleague.com/premierleague/photos/players/110x140/p${p.photoCode}.png`
      : null;
  }

  res.json(
    rows.map((r) => {
      const incoming = byId.get(r.playerId);
      const outgoingId =
        r.kind === "PLAY" && r.toSlot != null ? occupantBySlot.get(r.toSlot) : r.playerId;
      const outgoing = outgoingId != null ? byId.get(outgoingId) : null;
      return {
        id: r.id,
        kind: r.kind,
        toSlot: r.toSlot,
        effectiveAt: r.effectiveAt.toISOString(),
        createdAt: r.createdAt.toISOString(),
        incoming:
          r.kind === "PLAY"
            ? {
                playerId: r.playerId,
                name: incoming?.webName ?? "?",
                teamShort: incoming?.team.shortName ?? "?",
                position: incoming?.position ?? 0,
                photoUrl: photo(r.playerId),
              }
            : null,
        outgoing: outgoing
          ? {
              playerId: outgoing.id,
              name: outgoing.webName,
              teamShort: outgoing.team.shortName,
              position: outgoing.position,
              photoUrl: photo(outgoing.id),
            }
          : null,
      };
    }),
  );
});

router.delete("/pending/:id", async (req: AuthedRequest, res) => {
  const id = Number(req.params.id);
  const row = await prisma.pendingChange.findUnique({ where: { id } });
  if (!row || row.managerId !== req.managerId) {
    return res.status(404).json({ error: "not found" });
  }
  await prisma.pendingChange.delete({ where: { id } });
  res.json({ ok: true });
});

// Bidding + selling activity stream for the current manager. Combines every
// squad entry (buy + sell legs) with any lost / pending bids so the Squad
// page can show a chronological grid of "what I did this season".
router.get("/activity", async (req: AuthedRequest, res) => {
  const [entries, otherBids] = await Promise.all([
    prisma.squadEntry.findMany({
      where: { managerId: req.managerId },
      include: { player: { include: { team: true } } },
      orderBy: { fromAt: "desc" },
    }),
    prisma.bid.findMany({
      where: { managerId: req.managerId, OR: [{ won: false }, { resolved: false }] },
      include: { player: { include: { team: true } } },
    }),
  ]);

  type Entry = {
    when: string;
    kind: "signed" | "sold" | "outbid" | "pending";
    playerId: number;
    playerName: string;
    playerTeamShort: string;
    position: number;
    amount: number;
    bidPrice?: number; // for "sold" rows: what was paid originally
    delta?: number; // sellPrice − bid (negative = loss)
  };

  const activity: Entry[] = [];
  for (const e of entries) {
    activity.push({
      when: e.fromAt.toISOString(),
      kind: "signed",
      playerId: e.playerId,
      playerName: e.player.webName,
      playerTeamShort: e.player.team.shortName,
      position: e.player.position,
      amount: e.bid,
    });
    if (e.untilAt.toISOString() !== FOREVER.toISOString()) {
      const sellAmount = e.sellPrice ?? e.bid;
      activity.push({
        when: e.untilAt.toISOString(),
        kind: "sold",
        playerId: e.playerId,
        playerName: e.player.webName,
        playerTeamShort: e.player.team.shortName,
        position: e.player.position,
        amount: sellAmount,
        bidPrice: e.bid,
        delta: sellAmount - e.bid,
      });
    }
  }
  for (const b of otherBids) {
    activity.push({
      when: b.placedAt.toISOString(),
      kind: b.resolved ? "outbid" : "pending",
      playerId: b.playerId,
      playerName: b.player.webName,
      playerTeamShort: b.player.team.shortName,
      position: b.player.position,
      amount: b.amount,
    });
  }
  activity.sort((a, b) => b.when.localeCompare(a.when));
  res.json(activity);
});

// Per-gameweek breakdown for one player from the current manager's POV.
// For each GW: was the player owned, was the player starting (= contributed),
// and how many points did they score. The popup on the Squad page uses this
// to show "what did this player do for me this season?".
router.get("/player-history/:playerId", async (req: AuthedRequest, res) => {
  const playerId = Number(req.params.playerId);
  if (!Number.isInteger(playerId)) return res.status(400).json({ error: "bad playerId" });

  const [snapshots, entries, player] = await Promise.all([
    prisma.pointSnapshot.findMany({
      where: { playerId, kickoffTime: { not: null } },
      orderBy: { gameweek: "asc" },
    }),
    prisma.squadEntry.findMany({
      where: { managerId: req.managerId, playerId },
    }),
    prisma.player.findUnique({
      where: { id: playerId },
      include: { team: true },
    }),
  ]);

  if (!player) return res.status(404).json({ error: "player not found" });

  const history = snapshots.map((s) => {
    if (!s.kickoffTime) {
      return {
        gameweek: s.gameweek,
        kickoffTime: null,
        points: s.points,
        owned: false,
        playing: false,
        credited: 0,
      };
    }
    const k = s.kickoffTime;
    const owner = entries.find((e) => k >= e.fromAt && k < e.untilAt);
    const owned = Boolean(owner);
    const playing = Boolean(owner?.playing);
    return {
      gameweek: s.gameweek,
      kickoffTime: k.toISOString(),
      points: s.points,
      owned,
      playing,
      credited: playing ? s.points : 0,
    };
  });

  const totalCredited = history.reduce((s, r) => s + r.credited, 0);
  const totalScored = history.reduce((s, r) => s + r.points, 0);

  res.json({
    player: {
      id: player.id,
      name: player.webName,
      team: player.team.name,
      teamShort: player.team.shortName,
      position: player.position,
    },
    history,
    totalScored,
    totalCredited,
  });
});

router.delete("/:playerId", async (req: AuthedRequest, res) => {
  const playerId = Number(req.params.playerId);
  const now = new Date();
  const entry = await prisma.squadEntry.findFirst({
    where: { managerId: req.managerId, playerId, untilAt: FOREVER },
    include: { player: { include: { team: true } } },
  });
  if (!entry) return res.status(404).json({ error: "not owned" });
  // Sell at the current book price (Player.nowCost is in £×10). If you
  // overpaid at buy time, your funds fall by the difference.
  const sellPrice = entry.player.nowCost / 10;
  await prisma.squadEntry.update({
    where: { id: entry.id },
    data: { untilAt: now, playing: false, formationSlot: null, sellPrice },
  });
  await prisma.paperTalk.create({
    data: {
      managerId: req.managerId,
      teamName: entry.player.team.name,
      playerName: entry.player.webName,
      reason: "Sold",
      bid: sellPrice,
    },
  });
  res.json({ ok: true, sellPrice });
});

export default router;
