import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth, type AuthedRequest } from "../auth.js";
import { getBidMode } from "../settings.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 75);

router.use(requireAuth);

router.get("/", async (req: AuthedRequest, res) => {
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
  await prisma.manager.update({
    where: { id: req.managerId },
    data: { formation },
  });
  // Reset playing/slots if formation changes — invalid slots will be empty
  await prisma.squadEntry.updateMany({
    where: { managerId: req.managerId, untilAt: FOREVER },
    data: { playing: false, formationSlot: null },
  });
  res.json({ ok: true });
});

router.post("/play", async (req: AuthedRequest, res) => {
  const { playerId, slot } = req.body ?? {};
  if (typeof playerId !== "number" || typeof slot !== "number") {
    return res.status(400).json({ error: "playerId and slot required" });
  }
  // Validate slot fits formation and position
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

  // Free anyone else currently in that slot
  await prisma.squadEntry.updateMany({
    where: { managerId: req.managerId, formationSlot: slot, untilAt: FOREVER },
    data: { playing: false, formationSlot: null },
  });
  // Free this player from any other slot
  await prisma.squadEntry.update({
    where: { id: entry.id },
    data: { playing: true, formationSlot: slot },
  });
  res.json({ ok: true });
});

router.post("/bench", async (req: AuthedRequest, res) => {
  const { playerId } = req.body ?? {};
  if (typeof playerId !== "number") return res.status(400).json({ error: "playerId required" });
  await prisma.squadEntry.updateMany({
    where: { managerId: req.managerId, playerId, untilAt: FOREVER },
    data: { playing: false, formationSlot: null },
  });
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
