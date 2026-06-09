import { Router } from "express";
import { prisma } from "../prisma.js";
import {
  hash,
  verify,
  signToken,
  setAuthCookie,
  clearAuthCookie,
  requireAuth,
  isAdminUsername,
  type AuthedRequest,
} from "../auth.js";

const router = Router();

router.post("/register", async (req, res) => {
  const { username, password, teamName, email } = req.body ?? {};
  if (!username || !password || !teamName) {
    return res.status(400).json({ error: "username, password, teamName required" });
  }
  const existing = await prisma.manager.findUnique({ where: { username } });
  if (existing) return res.status(409).json({ error: "username taken" });
  const manager = await prisma.manager.create({
    data: {
      username,
      passwordHash: hash(password),
      teamName,
      email: email ?? null,
    },
  });
  await prisma.paperTalk.create({
    data: {
      managerId: manager.id,
      teamName: manager.teamName,
      reason: `${manager.teamName} joined the league.`,
    },
  });
  setAuthCookie(res, signToken(manager.id));
  res.json({ id: manager.id, username: manager.username, teamName: manager.teamName });
});

router.post("/login", async (req, res) => {
  const { username, password } = req.body ?? {};
  const manager = await prisma.manager.findUnique({ where: { username } });
  if (!manager || !verify(password ?? "", manager.passwordHash)) {
    return res.status(401).json({ error: "invalid credentials" });
  }
  setAuthCookie(res, signToken(manager.id));
  res.json({ id: manager.id, username: manager.username, teamName: manager.teamName });
});

router.post("/logout", (_req, res) => {
  clearAuthCookie(res);
  res.json({ ok: true });
});

router.get("/me", requireAuth, async (req: AuthedRequest, res) => {
  const manager = await prisma.manager.findUnique({
    where: { id: req.managerId },
    select: { id: true, username: true, teamName: true, email: true, formation: true },
  });
  if (!manager) return res.status(404).json({ error: "not found" });
  res.json({ ...manager, isAdmin: isAdminUsername(manager.username) });
});

export default router;
