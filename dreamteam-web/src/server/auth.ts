import type { Request, Response, NextFunction } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { prisma } from "./prisma.js";

const SECRET = process.env.JWT_SECRET ?? "dev-secret";
const COOKIE = "dt_token";

// Only these usernames (case-insensitive) may use the Admin area. Override with
// the ADMIN_USERNAMES env var (comma-separated) without touching code.
const ADMIN_USERNAMES = new Set(
  (process.env.ADMIN_USERNAMES ?? "chris,CWoolley")
    .split(",")
    .map((u) => u.trim().toLowerCase())
    .filter(Boolean),
);

export function isAdminUsername(username: string) {
  return ADMIN_USERNAMES.has(username.trim().toLowerCase());
}

export type AuthedRequest = Request & { managerId?: number };

export function hash(pw: string) {
  return bcrypt.hashSync(pw, 10);
}

export function verify(pw: string, h: string) {
  return bcrypt.compareSync(pw, h);
}

export function signToken(managerId: number) {
  return jwt.sign({ sub: managerId }, SECRET, { expiresIn: "30d" });
}

export function setAuthCookie(res: Response, token: string) {
  res.cookie(COOKIE, token, {
    httpOnly: true,
    sameSite: "lax",
    maxAge: 30 * 24 * 60 * 60 * 1000,
  });
}

export function clearAuthCookie(res: Response) {
  res.clearCookie(COOKIE);
}

export function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const token = req.cookies?.[COOKIE];
  if (!token) return res.status(401).json({ error: "unauthenticated" });
  try {
    const payload = jwt.verify(token, SECRET) as unknown as { sub: number };
    req.managerId = payload.sub;
    next();
  } catch {
    res.status(401).json({ error: "invalid token" });
  }
}

// Must run after requireAuth. Looks up the manager and rejects non-admins.
export async function requireAdmin(req: AuthedRequest, res: Response, next: NextFunction) {
  if (!req.managerId) return res.status(401).json({ error: "unauthenticated" });
  try {
    const manager = await prisma.manager.findUnique({
      where: { id: req.managerId },
      select: { username: true },
    });
    if (!manager || !isAdminUsername(manager.username)) {
      return res.status(403).json({ error: "admin only" });
    }
    next();
  } catch (err) {
    next(err);
  }
}
