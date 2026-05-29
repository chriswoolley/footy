import { Router } from "express";
import { prisma } from "../prisma.js";

const router = Router();

router.get("/", async (_req, res) => {
  const items = await prisma.paperTalk.findMany({
    orderBy: { when: "desc" },
    take: 200,
    include: { manager: { select: { teamName: true } } },
  });
  res.json(
    items.map((i) => ({
      id: i.id,
      when: i.when,
      manager: i.manager?.teamName ?? null,
      team: i.teamName,
      player: i.playerName,
      reason: i.reason,
      bid: i.bid,
    })),
  );
});

export default router;
