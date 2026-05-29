import { Router } from "express";
import { prisma } from "../prisma.js";
import { syncPlayerHistory } from "../fpl.js";

const router = Router();

router.get("/player/:id", async (req, res) => {
  const id = Number(req.params.id);
  // Fire-and-forget refresh
  syncPlayerHistory(id).catch(() => undefined);
  const points = await prisma.pointSnapshot.findMany({
    where: { playerId: id },
    orderBy: { gameweek: "asc" },
  });
  const player = await prisma.player.findUnique({
    where: { id },
    select: { webName: true, team: { select: { name: true } } },
  });
  res.json({
    player: player ? { name: player.webName, team: player.team.name } : null,
    series: points.map((p) => ({
      gameweek: p.gameweek,
      points: p.points,
      value: p.value / 10,
      kickoff: p.kickoffTime,
    })),
  });
});

// Per-gameweek total respecting the ownership window of each SquadEntry.
type Row = { gameweek: number; points: number | null };

router.get("/manager/:id", async (req, res) => {
  const id = Number(req.params.id);
  const rows = await prisma.$queryRawUnsafe<Row[]>(
    `
    SELECT ps.gameweek AS gameweek, COALESCE(SUM(ps.points), 0) AS points
    FROM SquadEntry se
    JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
     AND ps.kickoffTime IS NOT NULL
     AND ps.kickoffTime >= se.fromAt
     AND ps.kickoffTime <  se.untilAt
    WHERE se.managerId = ?
      AND se.playing = 1
    GROUP BY ps.gameweek
    ORDER BY ps.gameweek ASC
  `,
    id,
  );

  const manager = await prisma.manager.findUnique({
    where: { id },
    select: { teamName: true, username: true },
  });
  res.json({
    manager,
    series: rows.map((r) => ({ gameweek: r.gameweek, points: Number(r.points ?? 0) })),
  });
});

router.get("/leaderboard", async (_req, res) => {
  // top 20 players by total points
  const top = await prisma.player.findMany({
    orderBy: { totalPoints: "desc" },
    take: 20,
    include: { team: { select: { name: true, shortName: true } } },
  });
  res.json(
    top.map((p) => ({
      id: p.id,
      name: p.webName,
      team: p.team.shortName,
      position: p.position,
      points: p.totalPoints,
      price: p.nowCost / 10,
    })),
  );
});

export default router;
