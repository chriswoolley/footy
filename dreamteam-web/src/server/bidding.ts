import { prisma } from "./prisma.js";

const FOREVER = new Date("9999-12-31T00:00:00Z");

/**
 * Resolve every pending sealed bid in one transaction. For each player the
 * highest amount wins (tie → earliest placedAt); the winner's budget and squad
 * cap are re-checked at resolution time and the bid cascades to the next
 * affordable bidder if the leader can't afford it. Shared by the admin
 * "Run bids" endpoint and the scheduled auction.
 */
export async function resolvePendingBids(): Promise<{
  won: number;
  lost: number;
  skipped: number;
}> {
  return prisma.$transaction(async (tx) => {
    const pending = await tx.bid.findMany({
      where: { resolved: false },
      orderBy: [{ amount: "desc" }, { placedAt: "asc" }],
      include: { player: { include: { team: true } } },
    });
    if (pending.length === 0) return { won: 0, lost: 0, skipped: 0 };

    // Group by player
    const byPlayer = new Map<number, typeof pending>();
    for (const b of pending) {
      const list = byPlayer.get(b.playerId) ?? [];
      list.push(b);
      byPlayer.set(b.playerId, list);
    }

    let won = 0;
    let lost = 0;
    let skipped = 0;

    const BUDGET = Number(process.env.BUDGET ?? 150);
    const MAX_SQUAD = Number(process.env.MAX_SQUAD ?? 20);

    for (const [playerId, bids] of byPlayer) {
      // Skip if already owned
      const owner = await tx.squadEntry.findFirst({
        where: { playerId, untilAt: FOREVER },
      });
      if (owner) {
        for (const b of bids) {
          await tx.bid.update({ where: { id: b.id }, data: { resolved: true, won: false } });
          await tx.paperTalk.create({
            data: {
              managerId: b.managerId,
              teamName: b.player.team.name,
              playerName: b.player.webName,
              reason: "Outbid (player already taken)",
              bid: b.amount,
            },
          });
          skipped++;
        }
        continue;
      }

      const winner = bids[0];
      const losers = bids.slice(1);

      // Re-check the winner's budget at resolution time (sells refund book
      // price, so include realised losses from past sales).
      const winnerEntries = await tx.squadEntry.findMany({
        where: { managerId: winner.managerId, untilAt: FOREVER },
      });
      const winnerSoldEntries = await tx.squadEntry.findMany({
        where: { managerId: winner.managerId, untilAt: { lt: FOREVER } },
        select: { bid: true, sellPrice: true },
      });
      const winnerRealisedLosses = winnerSoldEntries.reduce(
        (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
        0,
      );
      const winnerSpent = winnerEntries.reduce((s, e) => s + e.bid, 0) + winnerRealisedLosses;
      if (winnerSpent + winner.amount > BUDGET + 1e-9 || winnerEntries.length >= MAX_SQUAD) {
        // Winner can no longer afford — skip; second highest gets a shot if any
        await tx.bid.update({ where: { id: winner.id }, data: { resolved: true, won: false } });
        await tx.paperTalk.create({
          data: {
            managerId: winner.managerId,
            teamName: winner.player.team.name,
            playerName: winner.player.webName,
            reason: "Bid void — budget or squad full",
            bid: winner.amount,
          },
        });
        skipped++;
        // Cascade to next bidder
        for (const b of losers) {
          const otherEntries = await tx.squadEntry.findMany({
            where: { managerId: b.managerId, untilAt: FOREVER },
          });
          const otherSoldEntries = await tx.squadEntry.findMany({
            where: { managerId: b.managerId, untilAt: { lt: FOREVER } },
            select: { bid: true, sellPrice: true },
          });
          const otherRealisedLosses = otherSoldEntries.reduce(
            (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
            0,
          );
          const otherSpent = otherEntries.reduce((s, e) => s + e.bid, 0) + otherRealisedLosses;
          if (otherSpent + b.amount <= BUDGET + 1e-9 && otherEntries.length < MAX_SQUAD) {
            await tx.bid.update({ where: { id: b.id }, data: { resolved: true, won: true } });
            await tx.squadEntry.create({
              data: { managerId: b.managerId, playerId, bid: b.amount, untilAt: FOREVER },
            });
            await tx.paperTalk.create({
              data: {
                managerId: b.managerId,
                teamName: b.player.team.name,
                playerName: b.player.webName,
                reason: "Signed",
                bid: b.amount,
              },
            });
            won++;
            // mark the rest as outbid
            for (const o of losers.filter((x) => x.id !== b.id)) {
              await tx.bid.update({ where: { id: o.id }, data: { resolved: true, won: false } });
              await tx.paperTalk.create({
                data: {
                  managerId: o.managerId,
                  teamName: o.player.team.name,
                  playerName: o.player.webName,
                  reason: "Outbid",
                  bid: o.amount,
                },
              });
              lost++;
            }
            break;
          }
        }
        continue;
      }

      // Award to highest bidder
      await tx.bid.update({ where: { id: winner.id }, data: { resolved: true, won: true } });
      await tx.squadEntry.create({
        data: { managerId: winner.managerId, playerId, bid: winner.amount, untilAt: FOREVER },
      });
      await tx.paperTalk.create({
        data: {
          managerId: winner.managerId,
          teamName: winner.player.team.name,
          playerName: winner.player.webName,
          reason: "Signed",
          bid: winner.amount,
        },
      });
      won++;

      for (const b of losers) {
        await tx.bid.update({ where: { id: b.id }, data: { resolved: true, won: false } });
        await tx.paperTalk.create({
          data: {
            managerId: b.managerId,
            teamName: b.player.team.name,
            playerName: b.player.webName,
            reason: "Outbid",
            bid: b.amount,
          },
        });
        lost++;
      }
    }

    return { won, lost, skipped };
  });
}
