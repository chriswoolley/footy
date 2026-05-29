/**
 * End-to-end simulation:
 *   1. Wipe managers / squads / bids / papertalk (keep FPL teams + players + snapshots)
 *   2. Create 8 managers
 *   3. Phase 1 — 8 pre-season bidding rounds. Each team targets a 2/5/5/4
 *      position composition (16 players total). All squad entries are dated
 *      `fromAt = SEASON_START` so they accrue points across the whole season.
 *   4. Set each team's 4-4-2 starting XI (1/4/4/2 = 11 slots, playing=true).
 *   5. Phase 2 — one mid-season weekly cycle (2026-01-15). Pick 4 droppers;
 *      each drops 1-2 same-position players, then bids same-position
 *      replacements. Resolve.
 *   6. Re-pick the XI for affected teams.
 *   7. Print standings (points come from FPL PointSnapshot rows joined to
 *      each manager's playing entries during their ownership window).
 *
 * Bid resolution mirrors admin.ts /run-bids semantics (highest amount, then
 * earliest placedAt; budget + squad-cap re-checked; cascade on void winner).
 */
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();
const FOREVER = new Date("9999-12-31T00:00:00Z");
const SEASON_START = new Date("2025-08-01T00:00:00Z");
const TRANSFER_DATE = new Date("2026-01-15T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 75);
const MAX_SQUAD = Number(process.env.MAX_SQUAD ?? 20);

const SQUAD_COMPOSITION = { 1: 2, 2: 5, 3: 5, 4: 4 } as const; // 2 GK, 5 DEF, 5 MID, 4 FWD = 16
const XI_LAYOUT_442 = { 1: 1, 2: 4, 3: 4, 4: 2 } as const;     // 4-4-2

// Position label, used only for logging.
const POS_NAMES = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

// Bidding plan — each round, each team bids on two players, weighted to
// fill the composition target. Position pairs across 8 rounds:
//   GK ×2 (rounds 1, 8)
//   DEF ×5 (1, 2, 3, 4, 8)
//   MID ×5 (2, 4, 5, 5, 6)
//   FWD ×4 (3, 6, 7, 7)
// = exactly 16 picks per team across 8 rounds.
const BID_PLAN: Array<[number, number]> = [
  [1, 2], // round 1: GK + DEF
  [2, 3], // round 2: DEF + MID
  [2, 4], // round 3: DEF + FWD
  [3, 2], // round 4: MID + DEF
  [3, 3], // round 5: MID + MID
  [3, 4], // round 6: MID + FWD
  [4, 4], // round 7: FWD + FWD
  [1, 2], // round 8: GK + DEF
];

const MANAGERS = [
  { username: "alice",  teamName: "Alice United" },
  { username: "bob",    teamName: "Bob Rovers" },
  { username: "carol",  teamName: "Carol City" },
  { username: "dave",   teamName: "Dave Wanderers" },
  { username: "eve",    teamName: "Eve Athletic" },
  { username: "frank",  teamName: "Frank FC" },
  { username: "grace",  teamName: "Grace Town" },
  { username: "henry",  teamName: "Henry Albion" },
] as const;

// Deterministic PRNG so the run is reproducible.
let seed = 42;
function rand() {
  seed = (seed * 1664525 + 1013904223) >>> 0;
  return seed / 0xffffffff;
}
function shuffle<T>(arr: T[]): T[] {
  const out = arr.slice();
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(rand() * (i + 1));
    [out[i], out[j]] = [out[j], out[i]];
  }
  return out;
}

// ── Bid resolution (mirrors admin.ts) ───────────────────────────────────────
async function resolveBids(opts: { entryFromAt: Date }): Promise<{ won: number; lost: number; skipped: number }> {
  return prisma.$transaction(async (tx) => {
    const pending = await tx.bid.findMany({
      where: { resolved: false },
      orderBy: [{ amount: "desc" }, { placedAt: "asc" }],
      include: { player: { include: { team: true } } },
    });
    if (pending.length === 0) return { won: 0, lost: 0, skipped: 0 };

    const byPlayer = new Map<number, typeof pending>();
    for (const b of pending) {
      const list = byPlayer.get(b.playerId) ?? [];
      list.push(b);
      byPlayer.set(b.playerId, list);
    }

    let won = 0, lost = 0, skipped = 0;
    for (const [playerId, bids] of byPlayer) {
      const owner = await tx.squadEntry.findFirst({
        where: { playerId, untilAt: FOREVER },
      });
      if (owner) {
        for (const b of bids) {
          await tx.bid.update({ where: { id: b.id }, data: { resolved: true, won: false } });
          await tx.paperTalk.create({
            data: {
              when: opts.entryFromAt,
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

      let awarded = false;
      for (let i = 0; i < bids.length; i++) {
        const cand = bids[i];
        const entries = await tx.squadEntry.findMany({
          where: { managerId: cand.managerId, untilAt: FOREVER },
        });
        const spent = entries.reduce((s, e) => s + e.bid, 0);
        if (spent + cand.amount > BUDGET + 1e-9 || entries.length >= MAX_SQUAD) {
          await tx.bid.update({ where: { id: cand.id }, data: { resolved: true, won: false } });
          await tx.paperTalk.create({
            data: {
              when: opts.entryFromAt,
              managerId: cand.managerId,
              teamName: cand.player.team.name,
              playerName: cand.player.webName,
              reason: "Bid void — budget or squad full",
              bid: cand.amount,
            },
          });
          skipped++;
          continue;
        }

        await tx.bid.update({ where: { id: cand.id }, data: { resolved: true, won: true } });
        await tx.squadEntry.create({
          data: {
            managerId: cand.managerId,
            playerId,
            bid: cand.amount,
            fromAt: opts.entryFromAt,
            untilAt: FOREVER,
          },
        });
        await tx.paperTalk.create({
          data: {
            when: opts.entryFromAt,
            managerId: cand.managerId,
            teamName: cand.player.team.name,
            playerName: cand.player.webName,
            reason: "Signed",
            bid: cand.amount,
          },
        });
        won++;
        awarded = true;
        for (const o of bids.slice(i + 1)) {
          await tx.bid.update({ where: { id: o.id }, data: { resolved: true, won: false } });
          await tx.paperTalk.create({
            data: {
              when: opts.entryFromAt,
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
      if (!awarded) skipped++;
    }

    return { won, lost, skipped };
  });
}

async function placeBid(managerId: number, playerId: number, amount: number) {
  await prisma.bid.create({
    data: { managerId, playerId, amount, resolved: false, won: false },
  });
}

async function squadByPosition(managerId: number): Promise<Record<number, number>> {
  const entries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER },
    include: { player: { select: { position: true } } },
  });
  const counts: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0 };
  for (const e of entries) counts[e.player.position]++;
  return counts;
}

async function unownedPlayersByPosition(position: number, maxCost: number, exclude: Set<number>) {
  // Cheapest first so 16 picks fit inside the £75m budget; the XI selector
  // then promotes the best scorers within each manager's squad.
  const players = await prisma.player.findMany({
    where: { position, nowCost: { lte: maxCost }, status: "a" },
    orderBy: [{ nowCost: "asc" }, { totalPoints: "desc" }, { id: "asc" }],
    select: { id: true, nowCost: true, webName: true, totalPoints: true },
  });
  const owned = await prisma.squadEntry.findMany({
    where: { untilAt: FOREVER },
    select: { playerId: true },
  });
  const ownedIds = new Set(owned.map((o) => o.playerId));
  return players.filter((p) => !ownedIds.has(p.id) && !exclude.has(p.id));
}

async function managerSpent(managerId: number) {
  const entries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER },
  });
  return entries.reduce((s, e) => s + e.bid, 0);
}

// ── XI selection ────────────────────────────────────────────────────────────
async function pickXI(managerId: number) {
  // Wipe current playing flags for this manager
  await prisma.squadEntry.updateMany({
    where: { managerId, untilAt: FOREVER },
    data: { playing: false, formationSlot: null },
  });

  const entries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER },
    include: { player: { select: { id: true, position: true, totalPoints: true, webName: true } } },
  });
  const byPos: Record<number, typeof entries> = { 1: [], 2: [], 3: [], 4: [] };
  for (const e of entries) byPos[e.player.position].push(e);
  // Best scorers first
  for (const k of [1, 2, 3, 4]) {
    byPos[k].sort((a, b) => b.player.totalPoints - a.player.totalPoints);
  }

  // 4-4-2 layout: slot 0 = GK, 1-4 = DEF, 5-8 = MID, 9-10 = FWD
  const slotIdxByPos: Record<number, number[]> = {
    1: [0],
    2: [1, 2, 3, 4],
    3: [5, 6, 7, 8],
    4: [9, 10],
  };

  let starters = 0;
  for (const pos of [1, 2, 3, 4]) {
    const need = XI_LAYOUT_442[pos as 1 | 2 | 3 | 4];
    const have = byPos[pos];
    if (have.length < need) {
      console.warn(
        `  manager ${managerId}: only ${have.length} ${POS_NAMES[pos as 1 | 2 | 3 | 4]}s, needs ${need}`,
      );
    }
    for (let i = 0; i < need && i < have.length; i++) {
      await prisma.squadEntry.update({
        where: { id: have[i].id },
        data: { playing: true, formationSlot: slotIdxByPos[pos][i] },
      });
      starters++;
    }
  }
  return starters;
}

// ── PHASE 0: reset ──────────────────────────────────────────────────────────
console.log("[sim] resetting manager-related tables");
await prisma.$transaction([
  prisma.bid.deleteMany({}),
  prisma.paperTalk.deleteMany({}),
  prisma.squadEntry.deleteMany({}),
  prisma.manager.deleteMany({}),
  prisma.audit.deleteMany({}),
]);

const hash = await bcrypt.hash("sim-password", 8);
const managers = [];
for (const m of MANAGERS) {
  const created = await prisma.manager.create({
    data: {
      username: m.username,
      passwordHash: hash,
      teamName: m.teamName,
      formation: "442",
    },
  });
  managers.push(created);
}
console.log(`[sim] created ${managers.length} managers`);

// ── PHASE 1: 8 pre-season rounds ────────────────────────────────────────────
console.log("\n[sim] PHASE 1: 8 pre-season bidding rounds (fromAt = season start)");
for (let round = 1; round <= 8; round++) {
  const [posA, posB] = BID_PLAN[round - 1];
  const usedThisRound = new Set<number>();

  for (const m of managers) {
    const counts = await squadByPosition(m.id);
    const remaining = BUDGET - (await managerSpent(m.id));

    for (const pos of [posA, posB]) {
      // Skip if already at the target for this position
      const target = SQUAD_COMPOSITION[pos as 1 | 2 | 3 | 4];
      if (counts[pos] >= target) continue;

      const pool = await unownedPlayersByPosition(pos, 65, usedThisRound);
      if (pool.length === 0) continue;
      const pick = pool[0];
      const amount = pick.nowCost / 10;
      if (amount > remaining) continue;
      await placeBid(m.id, pick.id, amount);
      usedThisRound.add(pick.id);
      counts[pos]++;
    }
  }

  // Contested bid in rounds 3, 5, 7 — extra bid by two managers on the
  // CHEAPEST unused player in the position they were already bidding.
  if (round === 3 || round === 5 || round === 7) {
    const pos = BID_PLAN[round - 1][0];
    const contested = (await unownedPlayersByPosition(pos, 65, usedThisRound))[0];
    if (contested) {
      const a = managers[round % managers.length];
      const b = managers[(round + 1) % managers.length];
      await placeBid(a.id, contested.id, contested.nowCost / 10 + 0.5);
      await placeBid(b.id, contested.id, contested.nowCost / 10 + 0.3);
      usedThisRound.add(contested.id);
    }
  }

  const r = await resolveBids({ entryFromAt: SEASON_START });
  const sizes = await Promise.all(
    managers.map(async (m) =>
      prisma.squadEntry.count({ where: { managerId: m.id, untilAt: FOREVER } }),
    ),
  );
  console.log(
    `  round ${round} (${POS_NAMES[posA as 1 | 2 | 3 | 4]}/${POS_NAMES[posB as 1 | 2 | 3 | 4]}): won=${r.won} lost=${r.lost} → [${sizes.join(", ")}]`,
  );
}

// ── Phase 1 squad summary ───────────────────────────────────────────────────
console.log("\n[sim] phase 1 squads:");
for (const m of managers) {
  const counts = await squadByPosition(m.id);
  const spent = await managerSpent(m.id);
  const total = counts[1] + counts[2] + counts[3] + counts[4];
  console.log(
    `  ${m.teamName.padEnd(20)} squad=${total}  GK=${counts[1]} DEF=${counts[2]} MID=${counts[3]} FWD=${counts[4]}  spent=£${spent.toFixed(1)}m`,
  );
}

// ── Set initial XI ──────────────────────────────────────────────────────────
console.log("\n[sim] picking initial 4-4-2 XI for each team…");
for (const m of managers) {
  const starters = await pickXI(m.id);
  if (starters !== 11) console.warn(`  ${m.teamName}: only ${starters}/11 starters`);
}

// ── PHASE 2: weekly cycle ───────────────────────────────────────────────────
console.log(
  `\n[sim] PHASE 2: weekly cycle (transfer date ${TRANSFER_DATE.toISOString().slice(0, 10)})`,
);
const droppers = shuffle(managers.slice()).slice(0, 4);
console.log(`  droppers: ${droppers.map((d) => d.teamName).join(", ")}`);

const usedInWeekly = new Set<number>(); // shared exclude so droppers don't collide
for (const d of droppers) {
  // Choose a position where this manager has surplus (>min XI requirement)
  const counts = await squadByPosition(d.id);
  const surplusPositions: number[] = [];
  for (const pos of [1, 2, 3, 4]) {
    if (counts[pos] - XI_LAYOUT_442[pos as 1 | 2 | 3 | 4] >= 1) surplusPositions.push(pos);
  }
  const pos = surplusPositions[Math.floor(rand() * surplusPositions.length)] ?? 2;
  const dropCount = Math.min(
    1 + Math.floor(rand() * 2), // 1 or 2
    counts[pos] - XI_LAYOUT_442[pos as 1 | 2 | 3 | 4],
  );

  const entries = await prisma.squadEntry.findMany({
    where: { managerId: d.id, untilAt: FOREVER, player: { position: pos } },
    include: { player: { include: { team: true } } },
  });
  const toDrop = shuffle(entries).slice(0, dropCount);

  for (const e of toDrop) {
    await prisma.squadEntry.update({
      where: { id: e.id },
      data: {
        untilAt: TRANSFER_DATE,
        playing: false,
        formationSlot: null,
      },
    });
    await prisma.paperTalk.create({
      data: {
        when: TRANSFER_DATE,
        managerId: d.id,
        teamName: e.player.team.name,
        playerName: e.player.webName,
        reason: "Released (weekly drop)",
        bid: e.bid,
      },
    });
  }
  console.log(
    `  ${d.teamName.padEnd(20)} dropped ${dropCount} ${POS_NAMES[pos as 1 | 2 | 3 | 4]}: ${toDrop.map((e) => e.player.webName).join(", ")}`,
  );

  // Bid for the same number of same-position replacements. Use the shared
  // usedInWeekly so two droppers don't both bid on the same cheapest player.
  const remaining = BUDGET - (await managerSpent(d.id));
  const replPool = await unownedPlayersByPosition(pos, 65, usedInWeekly);
  let placed = 0;
  for (const p of replPool) {
    if (placed >= dropCount) break;
    if (p.nowCost / 10 > remaining - placed * 4) continue;
    await placeBid(d.id, p.id, p.nowCost / 10);
    usedInWeekly.add(p.id);
    placed++;
  }
  console.log(`  ${d.teamName.padEnd(20)} placed ${placed} bid(s) for ${POS_NAMES[pos as 1 | 2 | 3 | 4]}`);
}

// Contested weekly bid between the first two droppers
if (droppers.length >= 2) {
  const [a, b] = droppers;
  const contested = (await unownedPlayersByPosition(2, 65, usedInWeekly))[0];
  if (contested) {
    await placeBid(a.id, contested.id, contested.nowCost / 10 + 0.8);
    await placeBid(b.id, contested.id, contested.nowCost / 10 + 0.4);
    console.log(
      `  contested weekly DEF bid: ${a.teamName} vs ${b.teamName} on ${contested.webName}`,
    );
  }
}

const weekly = await resolveBids({ entryFromAt: TRANSFER_DATE });
console.log(
  `[sim]   weekly bid resolution: won=${weekly.won} lost=${weekly.lost} skipped=${weekly.skipped}`,
);

// ── Re-pick XI for droppers (and anyone whose XI changed) ───────────────────
console.log("\n[sim] re-picking XI for affected teams…");
for (const d of droppers) {
  const starters = await pickXI(d.id);
  console.log(`  ${d.teamName.padEnd(20)} XI now: ${starters}/11 starters`);
}

// ── FINAL STATE: squads, lineups, standings ─────────────────────────────────
console.log("\n[sim] FINAL squad summary:");
for (const m of managers) {
  const counts = await squadByPosition(m.id);
  const spent = await managerSpent(m.id);
  const total = counts[1] + counts[2] + counts[3] + counts[4];
  const playing = await prisma.squadEntry.count({
    where: { managerId: m.id, untilAt: FOREVER, playing: true },
  });
  console.log(
    `  ${m.teamName.padEnd(20)} squad=${total} XI=${playing}/11 GK=${counts[1]} DEF=${counts[2]} MID=${counts[3]} FWD=${counts[4]}  spent=£${spent.toFixed(1)}m`,
  );
}

console.log("\n[sim] STANDINGS (sum of XI player FPL points within ownership window):");
const standings = await prisma.$queryRawUnsafe<
  Array<{ managerId: number; teamName: string; score: number | null }>
>(`
  SELECT
    m.id      AS managerId,
    m.teamName AS teamName,
    COALESCE(SUM(ps.points), 0) AS score
  FROM Manager m
  LEFT JOIN SquadEntry se
    ON se.managerId = m.id
   AND se.playing = 1
  LEFT JOIN PointSnapshot ps
    ON ps.playerId = se.playerId
   AND ps.kickoffTime IS NOT NULL
   AND ps.kickoffTime >= se.fromAt
   AND ps.kickoffTime <  se.untilAt
  GROUP BY m.id, m.teamName
  ORDER BY score DESC, m.teamName ASC
`);
let rank = 1;
for (const row of standings) {
  console.log(`  ${String(rank).padStart(2)}. ${row.teamName.padEnd(20)} ${Number(row.score)} pts`);
  rank++;
}

const totalActive = await prisma.squadEntry.count({ where: { untilAt: FOREVER } });
const totalReleased = await prisma.squadEntry.count({ where: { NOT: { untilAt: FOREVER } } });
const totalBids = await prisma.bid.count();
const totalPaperTalk = await prisma.paperTalk.count();
console.log(
  `\n[sim] totals: ${totalActive} active squad entries, ${totalReleased} released, ${totalBids} bids, ${totalPaperTalk} paperTalk rows`,
);

await prisma.$disconnect();
