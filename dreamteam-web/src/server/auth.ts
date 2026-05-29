import type { Request, Response, NextFunction } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const SECRET = process.env.JWT_SECRET ?? "dev-secret";
const COOKIE = "dt_token";

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
