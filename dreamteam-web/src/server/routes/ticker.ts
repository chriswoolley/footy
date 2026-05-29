import { Router } from "express";
import { prisma } from "../prisma.js";

const router = Router();

// Compute the next 01:00 UTC after `now`. Bidding closes daily at 01:00, so
// this is the deadline shown in the ticker.
function nextBidDeadline(now: Date): Date {
  const candidate = new Date(now);
  candidate.setUTCHours(1, 0, 0, 0);
  if (candidate <= now) candidate.setUTCDate(candidate.getUTCDate() + 1);
  return candidate;
}

router.get("/", async (_req, res) => {
  const now = new Date();
  const deadline = nextBidDeadline(now);
  const secondsUntilBidEnds = Math.max(
    0,
    Math.floor((deadline.getTime() - now.getTime()) / 1000),
  );

  // Last 30 signings (winning bids), most recent first. The ticker scrolls
  // through this list on the client.
  const lastWins = await prisma.bid.findMany({
    where: { resolved: true, won: true },
    orderBy: { placedAt: "desc" },
    take: 30,
    include: {
      manager: { select: { teamName: true } },
      player: { select: { webName: true } },
    },
  });

  res.json({
    serverTime: now.toISOString(),
    nextDeadline: deadline.toISOString(),
    secondsUntilBidEnds,
    transfers: lastWins.map((b) => ({
      player: b.player.webName,
      team: b.manager.teamName,
      amount: b.amount,
      when: b.placedAt.toISOString(),
    })),
  });
});

export default router;
