/**
 * Seeds historical league data for demos.
 *
 * Picks ten squads from the players already synced from FPL, dates them
 * back to the start of the 2025-26 Premier League season, applies a few
 * mid-season transfers per manager, and syncs each involved player's
 * per-gameweek history so date-windowed scoring has data to work with.
 */
import { prisma } from "./prisma.js";
import { syncPlayerHistory } from "./fpl.js";
import { hash } from "./auth.js";

const SEASON_START = new Date("2025-08-15T00:00:00Z");
const FOREVER = new Date("9999-12-31T00:00:00Z");
const TRANSFER_DATES = [
  new Date("2025-10-25T00:00:00Z"), // around GW9
  new Date("2026-01-15T00:00:00Z"), // around GW21
  new Date("2026-03-15T00:00:00Z"), // around GW29
];

// 10 managers — first one matches the existing `test` user (will be backdated)
const PROFILES: Array<{ username: string; teamName: string; password: string }> = [
  { username: "test", teamName: "Test FC", password: "test123" },
  { username: "rab", teamName: "Arsenal Loyalists", password: "rab123" },
  { username: "jrb", teamName: "Goal Diggers", password: "jrb123" },
  { username: "woolley", teamName: "Defenders' Den", password: "wool123" },
  { username: "richard", teamName: "Newcastle Knights", password: "rich123" },
  { username: "stacy", teamName: "MidField Marshals", password: "stacy123" },
  { username: "debra", teamName: "Bus Parkers", password: "deb123" },
  { username: "alan", teamName: "Champions Picks", password: "alan123" },
  { username: "kate", teamName: "Underdogs FC", password: "kate123" },
  { username: "tom", teamName: "Bench Warmers", password: "tom123" },
];

// Mulberry32 — deterministic PRNG so the demo data is reproducible
function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s + 0x6d2b79f5) >>> 0;
    let t = s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

type P = { id: number; position: number; nowCost: number; webName: string };

function pickSquad(rand: () => number, pool: P[], usedIds: Set<number>, budget = 750) {
  // budget is in £/10 to match nowCost units; £75m = 750
  const byPos: Record<number, P[]> = { 1: [], 2: [], 3: [], 4: [] };
  for (const p of pool) {
    if (!usedIds.has(p.id)) byPos[p.position].push(p);
  }
  // Shuffle each bucket using the PRNG so different managers pick different players
  for (const pos of [1, 2, 3, 4]) {
    const arr = byPos[pos];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
  }
  const needs: Array<[number, number]> = [
    [1, 1],
    [2, 4],
    [3, 4],
    [4, 2],
  ];
  const picks: P[] = [];
  let spent = 0;
  for (const [pos, count] of needs) {
    let found = 0;
    for (const p of byPos[pos]) {
      if (found >= count) break;
      if (spent + p.nowCost > budget) continue;
      picks.push(p);
      spent += p.nowCost;
      found++;
    }
    if (found < count) {
      // budget too tight — relax and take cheapest
      const cheapest = [...byPos[pos]].sort((a, b) => a.nowCost - b.nowCost);
      for (const p of cheapest) {
        if (found >= count) break;
        if (picks.includes(p)) continue;
        picks.push(p);
        spent += p.nowCost;
        found++;
      }
    }
  }
  return picks;
}

function pickReplacement(
  rand: () => number,
  pool: P[],
  position: number,
  excludeIds: Set<number>,
  maxCost: number,
): P | null {
  const candidates = pool.filter(
    (p) => p.position === position && !excludeIds.has(p.id) && p.nowCost <= maxCost,
  );
  if (candidates.length === 0) return null;
  // weight by points so plausible swaps pop up more often, with a bit of noise
  const top = candidates.slice(0, 30);
  return top[Math.floor(rand() * top.length)] ?? null;
}

export type SeedResult = {
  managersSeeded: number;
  totalTransfers: number;
  uniquePlayers: number;
  syncedHistories: number;
};

export async function seedHistory(log: (msg: string) => void = console.log): Promise<SeedResult> {
  log("Loading player pool…");
  const pool = (await prisma.player.findMany({
    where: { status: { in: ["a", "d"] } },
    orderBy: { totalPoints: "desc" },
    select: { id: true, position: true, nowCost: true, webName: true },
  })) as P[];
  if (pool.length === 0) {
    throw new Error("No players loaded — has the FPL bootstrap sync run?");
  }
  log(`Pool: ${pool.length} players`);

  // Wipe historical demo data so this script is idempotent
  log("Clearing old SquadEntry / Bid / PaperTalk rows…");
  await prisma.$transaction([
    prisma.squadEntry.deleteMany({}),
    prisma.bid.deleteMany({}),
    prisma.paperTalk.deleteMany({}),
  ]);

  let totalTransfers = 0;

  // We deliberately do NOT delete Managers — preserve any humans you've
  // registered. But we'll upsert the demo profiles below.

  const allPlayerIds = new Set<number>();
  // Players already owned by some manager — enforce 1 manager per player
  const claimed = new Set<number>();

  let seed = 42;
  for (const profile of PROFILES) {
    seed += 1;
    const rand = rng(seed);

    // 442 layout: slot 0=GK, 1-4=DEF, 5-8=MID, 9-10=FWD
    const slotPositions = [1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4];

    const squad = pickSquad(rand, pool, claimed);
    for (const p of squad) claimed.add(p.id);
    if (squad.length !== 11) {
      console.warn(`  ${profile.teamName}: only picked ${squad.length} players`);
      continue;
    }

    // Map players to slots respecting position
    const slotMap = new Map<number, P>();
    for (let slot = 0; slot < 11; slot++) {
      const pos = slotPositions[slot];
      const candidate = squad.find((p) => p.position === pos && ![...slotMap.values()].includes(p));
      if (candidate) slotMap.set(slot, candidate);
    }

    // Upsert manager
    const manager = await prisma.manager.upsert({
      where: { username: profile.username },
      update: { teamName: profile.teamName, formation: "442" },
      create: {
        username: profile.username,
        passwordHash: hash(profile.password),
        teamName: profile.teamName,
        formation: "442",
      },
    });

    // Initial 11 entries, dated to season start
    for (const [slot, player] of slotMap) {
      allPlayerIds.add(player.id);
      await prisma.squadEntry.create({
        data: {
          managerId: manager.id,
          playerId: player.id,
          bid: player.nowCost / 10,
          fromAt: SEASON_START,
          untilAt: FOREVER,
          playing: true,
          formationSlot: slot,
        },
      });
    }
    await prisma.paperTalk.create({
      data: {
        when: SEASON_START,
        managerId: manager.id,
        teamName: profile.teamName,
        reason: `${profile.teamName} joined the league.`,
      },
    });

    // 1–3 transfers across the season
    const transferCount = 1 + Math.floor(rand() * 3);
    const transferredSlots = new Set<number>();
    for (let t = 0; t < transferCount; t++) {
      // pick a date that hasn't been used yet for this manager
      const date = TRANSFER_DATES[t % TRANSFER_DATES.length];
      // pick a random slot we haven't transferred yet
      let slot = -1;
      for (let attempt = 0; attempt < 11; attempt++) {
        const s = Math.floor(rand() * 11);
        if (!transferredSlots.has(s)) {
          slot = s;
          break;
        }
      }
      if (slot < 0) break;
      transferredSlots.add(slot);

      const oldEntry = await prisma.squadEntry.findFirst({
        where: {
          managerId: manager.id,
          formationSlot: slot,
          untilAt: FOREVER,
        },
        include: { player: { include: { team: true } } },
      });
      if (!oldEntry) continue;

      const replacement = pickReplacement(
        rand,
        pool,
        oldEntry.player.position,
        claimed, // exclude every player claimed by any manager so far
        Math.max(oldEntry.player.nowCost + 20, 100), // allow up to £2m more
      );
      if (!replacement) continue;
      claimed.add(replacement.id);
      allPlayerIds.add(replacement.id);

      // Close out the old entry
      await prisma.squadEntry.update({
        where: { id: oldEntry.id },
        data: { untilAt: date, playing: false, formationSlot: null },
      });

      // New entry starts on transfer date
      await prisma.squadEntry.create({
        data: {
          managerId: manager.id,
          playerId: replacement.id,
          bid: replacement.nowCost / 10,
          fromAt: date,
          untilAt: FOREVER,
          playing: true,
          formationSlot: slot,
        },
      });

      // PaperTalk entries
      await prisma.paperTalk.create({
        data: {
          when: date,
          managerId: manager.id,
          teamName: oldEntry.player.team.name,
          playerName: oldEntry.player.webName,
          reason: "Sold",
          bid: oldEntry.bid,
        },
      });
      const replPlayer = await prisma.player.findUnique({
        where: { id: replacement.id },
        include: { team: true },
      });
      await prisma.paperTalk.create({
        data: {
          when: date,
          managerId: manager.id,
          teamName: replPlayer?.team.name ?? null,
          playerName: replPlayer?.webName ?? replacement.webName,
          reason: "Signed",
          bid: replacement.nowCost / 10,
        },
      });
    }

    totalTransfers += transferCount;
    log(
      `  ${profile.teamName.padEnd(22)}  ${slotMap.size}/11 starters, ${transferCount} transfers`,
    );
  }

  // Per-player history sync only applies to the FPL data source. The WC
  // source has no live results yet (tournament starts 11 June 2026).
  const hasFplData = await prisma.player.findFirst({
    where: { photoCode: { not: null } },
    select: { id: true },
  });
  let synced = 0;
  if (hasFplData) {
    log(`Syncing FPL history for ${allPlayerIds.size} unique players…`);
    for (const id of allPlayerIds) {
      const existing = await prisma.pointSnapshot.findFirst({
        where: { playerId: id, kickoffTime: { not: null } },
      });
      if (existing) continue;
      try {
        await syncPlayerHistory(id);
        synced++;
        if (synced % 10 === 0) log(`  synced ${synced}…`);
      } catch (err) {
        console.error(`  player ${id} failed`, err);
      }
    }
    log(`Synced ${synced} player histories.`);
  } else {
    log("Skipping per-player history sync (non-FPL data source).");
  }
  log("Done.");

  return {
    managersSeeded: PROFILES.length,
    totalTransfers,
    uniquePlayers: allPlayerIds.size,
    syncedHistories: synced,
  };
}

// CLI entry-point — only runs when this file is invoked directly
const invokedAsScript =
  import.meta.url.startsWith("file:") &&
  process.argv[1] &&
  import.meta.url === new URL(`file:///${process.argv[1].replaceAll("\\", "/")}`).href;

if (invokedAsScript) {
  seedHistory()
    .then(async () => {
      await prisma.$disconnect();
    })
    .catch(async (err) => {
      console.error(err);
      await prisma.$disconnect();
      process.exit(1);
    });
}
