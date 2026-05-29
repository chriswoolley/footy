import { prisma } from "./prisma.js";

const KEY = "bidMode";
export type BidMode = "immediate" | "deferred";

export async function getBidMode(): Promise<BidMode> {
  const row = await prisma.syncState.findUnique({ where: { key: KEY } });
  return row?.value === "deferred" ? "deferred" : "immediate";
}

export async function setBidMode(mode: BidMode): Promise<void> {
  await prisma.syncState.upsert({
    where: { key: KEY },
    update: { value: mode },
    create: { key: KEY, value: mode },
  });
}

export async function audit(who: string, what: string): Promise<void> {
  await prisma.audit.create({ data: { who, what } });
}
