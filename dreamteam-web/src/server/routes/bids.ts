import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth, type AuthedRequest } from "../auth.js";
import { getBidMode, audit } from "../settings.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 75);
const MIN_BID = 0.1; // £100k
const MAX_SQUAD = Number(process.env.MAX_SQUAD ?? 20);

router.use(requireAuth);

router.get("/", async (req: AuthedRequest, res) => {
  const bids = await prisma.bid.findMany({
    where: { managerId: req.managerId, resolved: false },
    include: { player: { include: { team: true } } },
    orderBy: { placedAt: "desc" },
  });
  res.json(
    bids.map((b) => ({
      id: b.id,
      playerId: b.playerId,
      name: b.player.webName,
      team: b.player.team.name,
      teamShort: b.player.team.shortName,
      position: b.player.position,
      amount: b.amount,
      placedAt: b.placedAt,
    })),
  );
});

router.post("/", async (req: AuthedRequest, res) => {
  const { playerId, amount } = req.body ?? {};
  if (typeof playerId !== "number" || !Number.isInteger(playerId)) {
    return res.status(400).json({ error: "playerId must be an integer" });
  }
  if (typeof amount !== "number" || !Number.isFinite(amount)) {
    return res.status(400).json({ error: "amount must be a finite number" });
  }
  if (amount < MIN_BID) {
    return res.status(400).json({ error: `minimum bid is £${MIN_BID.toFixed(1)}m` });
  }
  if (amount > BUDGET) {
    return res.status(400).json({ error: `bid cannot exceed budget of £${BUDGET}m` });
  }

  const player = await prisma.player.findUnique({
    where: { id: playerId },
    include: { team: true },
  });
  if (!player) return res.status(404).json({ error: "player not found" });

  // Bids below the player's current book price are not allowed — selling a
  // player only refunds book, so a sub-book bid would mean the league loses
  // money to a phantom counter-party.
  const book = player.nowCost / 10;
  if (amount < book - 1e-9) {
    return res.status(400).json({
      error: `bid must be at least book price £${book.toFixed(1)}m`,
      bookPrice: book,
    });
  }

  const mode = await getBidMode();

  try {
    const result = await prisma.$transaction(async (tx) => {
      const owned = await tx.squadEntry.findFirst({
        where: { managerId: req.managerId, playerId, untilAt: FOREVER },
      });
      if (owned) throw new BidError(400, "you already own this player");

      // In immediate mode another manager already owning the player kills
      // the bid up-front. In deferred mode we still permit the bid (the
      // resolution step will decide who wins), but we never let *anyone*
      // bid for a player they personally own.
      if (mode === "immediate") {
        const ownedByOther = await tx.squadEntry.findFirst({
          where: { playerId, untilAt: FOREVER, NOT: { managerId: req.managerId } },
          include: { manager: { select: { teamName: true } } },
        });
        if (ownedByOther) {
          throw new BidError(409, `already owned by ${ownedByOther.manager.teamName}`);
        }
      }

      // Already bid for this player (deferred mode only)
      const existingBid = await tx.bid.findFirst({
        where: { managerId: req.managerId, playerId, resolved: false },
      });
      if (existingBid) {
        throw new BidError(400, `you already have a pending bid of £${existingBid.amount}m`);
      }

      const entries = await tx.squadEntry.findMany({
        where: { managerId: req.managerId, untilAt: FOREVER },
      });
      if (entries.length >= MAX_SQUAD) {
        throw new BidError(400, `squad is full (max ${MAX_SQUAD}) — sell someone first`);
      }
      // Sells now refund book price, not the original bid. Subtract realised
      // losses on past sales so overpayers don't get phantom budget back.
      const soldEntries = await tx.squadEntry.findMany({
        where: { managerId: req.managerId, untilAt: { lt: FOREVER } },
        select: { bid: true, sellPrice: true },
      });
      const realisedLosses = soldEntries.reduce(
        (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
        0,
      );
      const spent = entries.reduce((s, e) => s + e.bid, 0) + realisedLosses;

      // Reserve budget for *all* of this manager's pending bids
      const pendingBids = await tx.bid.findMany({
        where: { managerId: req.managerId, resolved: false },
      });
      const pending = pendingBids.reduce((s, b) => s + b.amount, 0);

      if (spent + pending + amount > BUDGET + 1e-9) {
        throw new BidError(400, "exceeds budget", {
          balance: BUDGET - spent - pending,
        });
      }

      const bid = await tx.bid.create({
        data: {
          managerId: req.managerId!,
          playerId,
          amount,
          resolved: mode === "immediate",
          won: mode === "immediate",
        },
      });

      if (mode === "immediate") {
        await tx.squadEntry.create({
          data: {
            managerId: req.managerId!,
            playerId,
            bid: amount,
            untilAt: FOREVER,
          },
        });
        await tx.paperTalk.create({
          data: {
            managerId: req.managerId,
            teamName: player.team.name,
            playerName: player.webName,
            reason: "Signed",
            bid: amount,
          },
        });
      }
      return { bidId: bid.id, mode };
    });

    res.json({ ok: true, ...result });
  } catch (err) {
    if (err instanceof BidError) {
      return res.status(err.status).json({ error: err.message, ...err.extra });
    }
    throw err;
  }
});

router.delete("/:id", async (req: AuthedRequest, res) => {
  const id = Number(req.params.id);
  const bid = await prisma.bid.findUnique({ where: { id } });
  if (!bid || bid.managerId !== req.managerId) {
    return res.status(404).json({ error: "not found" });
  }
  if (bid.resolved) {
    return res.status(400).json({
      error: "bid already resolved — to undo, sell the player via DELETE /api/squad/:playerId",
    });
  }
  await prisma.bid.delete({ where: { id } });
  await audit(`manager:${req.managerId}`, `cancelled bid #${id}`);
  res.json({ ok: true });
});

class BidError extends Error {
  status: number;
  extra: Record<string, unknown>;
  constructor(status: number, message: string, extra: Record<string, unknown> = {}) {
    super(message);
    this.status = status;
    this.extra = extra;
  }
}

export default router;
