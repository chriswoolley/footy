import { Router } from "express";
import { prisma } from "../prisma.js";
import { syncPlayerHistory } from "../fpl.js";

const router = Router();
const FOREVER = new Date("9999-12-31T00:00:00Z");

router.get("/", async (req, res) => {
  const position = req.query.position ? Number(req.query.position) : undefined;
  const maxPrice = req.query.maxPrice ? Number(req.query.maxPrice) : undefined;
  const search = (req.query.q as string | undefined)?.trim();

  const where: any = {};
  if (position) where.position = position;
  if (maxPrice !== undefined) where.nowCost = { lte: Math.round(maxPrice * 10) };
  if (search) where.webName = { contains: search };

  const players = await prisma.player.findMany({
    where,
    include: { team: { select: { name: true, shortName: true } } },
    orderBy: [{ totalPoints: "desc" }, { webName: "asc" }],
    take: 500,
  });

  // Look up current owners in one query
  const ownerships = await prisma.squadEntry.findMany({
    where: {
      playerId: { in: players.map((p) => p.id) },
      untilAt: FOREVER,
    },
    select: {
      playerId: true,
      managerId: true,
      manager: { select: { teamName: true } },
    },
  });
  const ownerByPlayer = new Map<number, { managerId: number; teamName: string }>();
  for (const o of ownerships) {
    ownerByPlayer.set(o.playerId, { managerId: o.managerId, teamName: o.manager.teamName });
  }

  res.json(
    players.map((p) => {
      const owner = ownerByPlayer.get(p.id);
      return {
        id: p.id,
        name: p.webName,
        firstName: p.firstName,
        lastName: p.lastName,
        team: p.team.name,
        teamShort: p.team.shortName,
        teamId: p.teamId,
        position: p.position,
        price: p.nowCost / 10,
        points: p.totalPoints,
        form: p.form,
        status: p.status,
        news: p.news,
        photoUrl: p.photoCode
          ? `https://resources.premierleague.com/premierleague/photos/players/110x140/p${p.photoCode}.png`
          : null,
        ownedBy: owner ? { managerId: owner.managerId, teamName: owner.teamName } : null,
      };
    }),
  );
});

router.get("/:id", async (req, res) => {
  const id = Number(req.params.id);
  const player = await prisma.player.findUnique({
    where: { id },
    include: { team: true, points: { orderBy: { gameweek: "asc" } } },
  });
  if (!player) return res.status(404).json({ error: "not found" });
  res.json(player);
});

router.get("/:id/history", async (req, res) => {
  const id = Number(req.params.id);
  syncPlayerHistory(id).catch(() => undefined);
  const points = await prisma.pointSnapshot.findMany({
    where: { playerId: id },
    orderBy: { gameweek: "asc" },
  });
  res.json(points);
});

export default router;
