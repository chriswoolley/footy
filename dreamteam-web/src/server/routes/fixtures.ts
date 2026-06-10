import { Router } from "express";
import { prisma } from "../prisma.js";
import { requireAuth } from "../auth.js";
import { plFixturesByDay } from "../fpl.js";
import { fixturesByDay } from "../fifaFantasy.js";

// Fixtures are visible to any logged-in manager (not admin-only).
const router = Router();
router.use(requireAuth);

router.get("/", async (_req, res) => {
  try {
    const teamCount = await prisma.team.count();
    // 20 teams ≈ PL; 48 ≈ WC. Fall back to WC if no teams are loaded.
    const grouped = teamCount === 20 ? await plFixturesByDay() : await fixturesByDay();
    res.json(grouped);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
