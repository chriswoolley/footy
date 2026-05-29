import { Router } from "express";
import { prisma } from "../prisma.js";

const router = Router();

// Manager's score = sum of points scored by players in their starting XI
// during the time window the manager owned each player. Implemented via raw
// SQL so SQLite can do the date-range join in one pass.
type Row = {
  managerId: number;
  username: string;
  teamName: string;
  squadSize: number;
  score: number | null;
};

router.get("/", async (_req, res) => {
  const rows = await prisma.$queryRawUnsafe<Row[]>(`
    SELECT
      m.id                                            AS managerId,
      m.username                                      AS username,
      m.teamName                                      AS teamName,
      COUNT(DISTINCT CASE WHEN se.playing = 1 AND se.untilAt > strftime('%s','now')*1000
                          THEN se.playerId END)       AS squadSize,
      COALESCE(SUM(ps.points), 0)                     AS score
    FROM Manager m
    LEFT JOIN SquadEntry se
      ON se.managerId = m.id
     AND se.playing = 1
    LEFT JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
     AND ps.kickoffTime IS NOT NULL
     AND ps.kickoffTime >= se.fromAt
     AND ps.kickoffTime <  se.untilAt
    GROUP BY m.id, m.username, m.teamName
    ORDER BY score DESC, m.teamName ASC
  `);

  res.json(
    rows.map((r, idx) => ({
      rank: idx + 1,
      id: r.managerId,
      username: r.username,
      teamName: r.teamName,
      squadSize: Number(r.squadSize ?? 0),
      score: Number(r.score ?? 0),
    })),
  );
});

export default router;
