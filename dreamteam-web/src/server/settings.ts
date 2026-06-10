import { prisma } from "./prisma.js";

// Bidding is always deferred (sealed-bid auction): bids stack as pending and
// are settled together when the resolution runs.

export async function audit(who: string, what: string): Promise<void> {
  await prisma.audit.create({ data: { who, what } });
}
