/**
 * Full-season simulation:
 *   1. Wipes the DB completely.
 *   2. Re-syncs FPL bootstrap (teams + players for the just-ended season).
 *   3. Creates 8 managers with starter XIs at SEASON_START.
 *   4. Walks the season day by day. Bids resolve every day at 01:00.
 *      One manager per week (round-robin) attempts an improving swap:
 *      sells their lowest cumulative-points starter and bids for the
 *      best affordable same-position upgrade available at that point.
 *   5. Syncs each owned player's per-gameweek history so date-windowed
 *      standings can score them.
 */
import { prisma } from "./prisma.js";
import { syncBootstrap, syncPlayerHistory } from "./fpl.js";
import { hash } from "./auth.js";

const FOREVER = new Date("9999-12-31T00:00:00Z");
const SEASON_START = new Date("2025-08-15T00:00:00Z");
const SEASON_END = new Date("2026-05-26T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 75);

const PROFILES: Array<{ username: string; teamName: string; password: string }> = [
  { username: "rab", teamName: "Arsenal Loyalists", password: "rab123" },
  { username: "jrb", teamName: "Goal Diggers", password: "jrb123" },
  { username: "woolley", teamName: "Defenders' Den", password: "wool123" },
  { username: "richard", teamName: "Newcastle Knights", password: "rich123" },
  { username: "stacy", teamName: "MidField Marshals", password: "stacy123" },
  { username: "debra", teamName: "Bus Parkers", password: "deb123" },
  { username: "alan", teamName: "Champions Picks", password: "alan123" },
  { username: "kate", teamName: "Underdogs FC", password: "kate123" },
  { username: "tom", teamName: "Bench Warmers", password: "tom123" },
  { username: "pete", teamName: "Penalty Kings", password: "pete123" },
  { username: "jane", teamName: "Counter Attackers", password: "jane123" },
  { username: "max", teamName: "Set-Piece Specialists", password: "max123" },
  { username: "eve", teamName: "Tactical Titans", password: "eve123" },
  { username: "luke", teamName: "Wing Wizards", password: "luke123" },
  { username: "sam", teamName: "Sweeper Keepers", password: "sam123" },
  { username: "olly", teamName: "Touchline Tornados", password: "olly123" },
  { username: "nina", teamName: "Aggressors United", password: "nina123" },
  { username: "ben", teamName: "Penalty Box Brawlers", password: "ben123" },
  { username: "rachel", teamName: "Final Third FC", password: "rachel123" },
  { username: "owen", teamName: "Stoppage Time XI", password: "owen123" },
  { username: "henry", teamName: "Header Hunters", password: "henry123" },
  { username: "polly", teamName: "Press Resistance", password: "polly123" },
  { username: "graham", teamName: "Crosshair Crossers", password: "graham123" },
  { username: "ivy", teamName: "Volley Vipers", password: "ivy123" },
  { username: "frank", teamName: "Box-to-Box Bandits", password: "frank123" },
  { username: "leo", teamName: "Throw-In Thieves", password: "leo123" },
  { username: "mia", teamName: "Offside Orcs", password: "mia123" },
  { username: "nate", teamName: "Counter Punch FC", password: "nate123" },
  { username: "ali", teamName: "Goal Line Guards", password: "ali123" },
  { username: "vera", teamName: "Substitute Stars", password: "vera123" },
  { username: "zoe", teamName: "Park-the-Bus FC", password: "zoe123" },
  { username: "ryan", teamName: "Direct Runners", password: "ryan123" },
  { username: "amelia", teamName: "Long Throw Lions", password: "amelia123" },
  { username: "noah", teamName: "Tiki-Taka Tigers", password: "noah123" },
  { username: "ella", teamName: "Gegenpress Gang", password: "ella123" },
  { username: "kit", teamName: "Catenaccio Crew", password: "kit123" },
  { username: "milo", teamName: "Total Football XI", password: "milo123" },
  { username: "sara", teamName: "Long Ball Legends", password: "sara123" },
  { username: "drew", teamName: "Wide Wing Wonders", password: "drew123" },
  { username: "elsa", teamName: "Last Minute Heroes", password: "elsa123" },
];

// 40 teams × 20 unique players ≈ 800 against an ~841 pool with strict per-
// position caps that none of the standard fixed compositions fit. So we
// guarantee each team the 1-4-4-2 starting-XI minimum first, then top up
// from any-position cheapest fillers until SQUAD_TARGET — some teams may
// finish at SQUAD_TARGET − 1 once the FWD/DEF pool runs out.
const SQUAD_TARGET = 20;
const SQUAD_MIN = 11;
// Backwards-compat: integrity check + bench-count uses SQUAD_SIZE.
// Treat as "target" — managers may have 19..20 depending on pool exhaustion.
const SQUAD_SIZE = SQUAD_TARGET;
const STARTERS_BY_POS: Record<number, number> = { 1: 1, 2: 4, 3: 4, 4: 2 };

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

type P = {
  id: number;
  position: number;
  nowCost: number;
  webName: string;
  totalPoints: number;
};

type Log = (msg: string) => void;

// 442 starting XI: slot 0=GK, 1..4=DEF, 5..8=MID, 9..10=FWD
const SLOT_POSITIONS = [1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4];

async function wipeAll(log: Log): Promise<void> {
  log("Wiping all data…");
  // Order matters — children first because of FK constraints.
  await prisma.audit.deleteMany({});
  await prisma.paperTalk.deleteMany({});
  await prisma.bid.deleteMany({});
  await prisma.squadEntry.deleteMany({});
  await prisma.pointSnapshot.deleteMany({});
  await prisma.manager.deleteMany({});
  await prisma.player.deleteMany({});
  await prisma.team.deleteMany({});
  await prisma.syncState.deleteMany({});
}

async function resyncFpl(log: Log): Promise<void> {
  log("Syncing FPL bootstrap…");
  const data = await syncBootstrap();
  log(`  ${data.teams.length} teams, ${data.elements.length} players loaded`);
}

async function loadPool(): Promise<P[]> {
  // With 30 managers × 20 players = 600 unique players we can no longer
  // restrict to status a/d (~574). Include everyone FPL knows about; injured
  // and suspended players become low-totalPoints filler that gets bought
  // cheaply and rarely chosen as upgrade targets.
  return (await prisma.player.findMany({
    orderBy: { totalPoints: "desc" },
    select: {
      id: true,
      position: true,
      nowCost: true,
      webName: true,
      totalPoints: true,
    },
  })) as P[];
}

function pickInitialSquad(
  rand: () => number,
  pool: P[],
  claimed: Set<number>,
  budgetTimesTen: number,
): P[] {
  const byPos: Record<number, P[]> = { 1: [], 2: [], 3: [], 4: [] };
  for (const p of pool) {
    if (!claimed.has(p.id)) byPos[p.position].push(p);
  }
  for (const pos of [1, 2, 3, 4]) {
    byPos[pos].sort((a, b) => b.totalPoints - a.totalPoints);
    const top = byPos[pos].slice(0, 30);
    for (let i = top.length - 1; i > 0; i--) {
      const j = Math.floor(rand() * (i + 1));
      [top[i], top[j]] = [top[j], top[i]];
    }
    byPos[pos] = top.concat(byPos[pos].slice(30));
  }

  const picks: P[] = [];
  const pickedIds = new Set<number>();
  const posCount: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0 };
  let spent = 0;

  // Step 1: cheapest starting-XI minimum at each position (1-4-4-2).
  for (const [pos, count] of [[1, 1], [2, 4], [3, 4], [4, 2]] as const) {
    const cheapest = [...byPos[pos]].sort((a, b) => a.nowCost - b.nowCost);
    for (let i = 0; i < count; i++) {
      const p = cheapest[i];
      if (!p) continue;
      picks.push(p);
      pickedIds.add(p.id);
      posCount[pos]++;
      spent += p.nowCost;
    }
  }
  if (picks.length < SQUAD_MIN) {
    // Pool is genuinely too thin at some position — caller will detect.
    return picks;
  }

  // Per-position caps: with 40 teams and pool sizes (GK 97 / DEF 270 / MID
  // 379 / FWD 95) the per-team ceiling is 2/6/9/2 = 19. Keep step 2 inside
  // those caps so no one team drains a position pool dry for later teams.
  const maxPerPos: Record<number, number> = { 1: 2, 2: 6, 3: 9, 4: 2 };

  // Precompute the cheapest unclaimed-at-this-position list once, refresh
  // lazily as we pick. Outer byPos[] is in totalPoints-desc order so we keep
  // a per-position cheapest sort.
  const cheapestByPos: Record<number, P[]> = { 1: [], 2: [], 3: [], 4: [] };
  for (const pos of [1, 2, 3, 4]) {
    cheapestByPos[pos] = [...byPos[pos]].sort((a, b) => a.nowCost - b.nowCost);
  }
  function pickCheapestRespectingCaps(allowOverCap: boolean): { p: P; pos: number } | null {
    let best: { p: P; pos: number } | null = null;
    for (const pos of [1, 2, 3, 4]) {
      if (!allowOverCap && posCount[pos]! >= maxPerPos[pos]!) continue;
      // Find first unclaimed-and-affordable at this position.
      for (const p of cheapestByPos[pos]) {
        if (pickedIds.has(p.id)) continue;
        if (spent + p.nowCost > budgetTimesTen) continue;
        if (!best || p.nowCost < best.p.nowCost) best = { p, pos };
        break;
      }
    }
    return best;
  }

  // Step 2: fill toward SQUAD_TARGET, respecting per-pos caps.
  while (picks.length < SQUAD_TARGET) {
    const bestPick = pickCheapestRespectingCaps(false);
    if (!bestPick) break;
    picks.push(bestPick.p);
    pickedIds.add(bestPick.p.id);
    posCount[bestPick.pos]++;
    spent += bestPick.p.nowCost;
  }

  // Step 2½: caps top out at 19; relax once and grab any cheapest extra to
  // round us up to 20 if pool/budget allow.
  if (picks.length < SQUAD_TARGET) {
    const bestPick = pickCheapestRespectingCaps(true);
    if (bestPick) {
      picks.push(bestPick.p);
      pickedIds.add(bestPick.p.id);
      posCount[bestPick.pos]++;
      spent += bestPick.p.nowCost;
    }
  }

  // Step 3: greedy upgrades within budget — for each high-totalPoints
  // candidate, swap in for the lowest-totalPoints same-position pick.
  for (const pos of [1, 2, 3, 4]) {
    for (const upgrade of byPos[pos]) {
      if (pickedIds.has(upgrade.id)) continue;
      const samePosPicks = picks
        .map((p, idx) => ({ p, idx }))
        .filter(({ p }) => p.position === pos)
        .sort((a, b) => a.p.totalPoints - b.p.totalPoints);
      const worst = samePosPicks[0];
      if (!worst || upgrade.totalPoints <= worst.p.totalPoints) continue;
      const delta = upgrade.nowCost - worst.p.nowCost;
      if (spent + delta <= budgetTimesTen) {
        pickedIds.delete(worst.p.id);
        pickedIds.add(upgrade.id);
        picks[worst.idx] = upgrade;
        spent += delta;
      }
    }
  }

  return picks;
}

async function seedInitialSquads(
  pool: P[],
  log: Log,
  squadBudgetTimesTen: number = BUDGET * 10,
): Promise<{ managerIds: number[]; claimed: Set<number> }> {
  log(`Creating ${PROFILES.length} managers with ${SQUAD_SIZE}-player squads…`);
  const claimed = new Set<number>();
  const managerIds: number[] = [];
  // Day-before-season bids: placed 2025-08-14 18:00, resolved at 2025-08-15 01:00.
  const bidPlacedAt = new Date("2025-08-14T18:00:00Z");
  const bidResolvedAt = new Date("2025-08-15T01:00:00Z");
  let seed = 100;
  for (const profile of PROFILES) {
    seed += 1;
    const rand = rng(seed);
    const squad = pickInitialSquad(rand, pool, claimed, squadBudgetTimesTen);
    if (squad.length < SQUAD_MIN) {
      throw new Error(`${profile.teamName}: only got ${squad.length} (need ≥ ${SQUAD_MIN})`);
    }
    for (const p of squad) claimed.add(p.id);

    const manager = await prisma.manager.create({
      data: {
        username: profile.username,
        passwordHash: hash(profile.password),
        teamName: profile.teamName,
        formation: "442",
      },
    });
    managerIds.push(manager.id);

    // Pick the strongest player at each starting-XI position (by season points)
    // to be the starter; remaining at each position go to the bench.
    const byPos: Record<number, P[]> = { 1: [], 2: [], 3: [], 4: [] };
    for (const p of squad) byPos[p.position].push(p);
    for (const pos of [1, 2, 3, 4]) {
      byPos[pos].sort((a, b) => b.totalPoints - a.totalPoints);
    }
    const starters: P[] = [];
    const bench: P[] = [];
    for (const pos of [1, 2, 3, 4]) {
      const need = STARTERS_BY_POS[pos];
      starters.push(...byPos[pos].slice(0, need));
      bench.push(...byPos[pos].slice(need));
    }
    if (starters.length !== 11) {
      throw new Error(`${profile.teamName}: starters=${starters.length}, expected 11`);
    }
    // Bench is squad-size − 11; squad size may legitimately be < SQUAD_TARGET
    // if the pool ran out at some position.
    const expectedBench = squad.length - 11;
    if (bench.length !== expectedBench) {
      throw new Error(`${profile.teamName}: bench=${bench.length}, expected ${expectedBench}`);
    }

    // Assign starters to 442 slots 0..10 by position.
    const remainingStarters = [...starters];
    for (let slot = 0; slot < 11; slot++) {
      const pos = SLOT_POSITIONS[slot];
      const idx = remainingStarters.findIndex((p) => p.position === pos);
      if (idx === -1) throw new Error(`could not fill slot ${slot} for ${profile.teamName}`);
      const player = remainingStarters.splice(idx, 1)[0]!;

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
      await prisma.bid.create({
        data: {
          managerId: manager.id,
          playerId: player.id,
          amount: player.nowCost / 10,
          placedAt: bidPlacedAt,
          resolved: true,
          won: true,
        },
      });
    }

    // Bench: owned but not playing, no formation slot. These accrue ownership
    // costs against the budget but contribute zero points to the standings.
    for (const player of bench) {
      await prisma.squadEntry.create({
        data: {
          managerId: manager.id,
          playerId: player.id,
          bid: player.nowCost / 10,
          fromAt: SEASON_START,
          untilAt: FOREVER,
          playing: false,
          formationSlot: null,
        },
      });
      await prisma.bid.create({
        data: {
          managerId: manager.id,
          playerId: player.id,
          amount: player.nowCost / 10,
          placedAt: bidPlacedAt,
          resolved: true,
          won: true,
        },
      });
    }

    await prisma.paperTalk.create({
      data: {
        when: bidResolvedAt,
        managerId: manager.id,
        teamName: profile.teamName,
        reason: `${profile.teamName} joined with ${squad.length} players (11 starters, ${squad.length - 11} bench).`,
      },
    });
    log(`  ${profile.teamName.padEnd(22)}  ${squad.length} players (11 + ${squad.length - 11} bench)`);
  }
  return { managerIds, claimed };
}

async function syncHistoriesForOwned(log: Log): Promise<number> {
  const owned = await prisma.squadEntry.findMany({ select: { playerId: true } });
  const ids = new Set(owned.map((o) => o.playerId));
  log(`Syncing per-gameweek history for ${ids.size} owned players…`);
  let synced = 0;
  let skipped = 0;
  for (const id of ids) {
    const existing = await prisma.pointSnapshot.findFirst({
      where: { playerId: id, kickoffTime: { not: null } },
    });
    if (existing) {
      skipped++;
      continue;
    }
    try {
      await syncPlayerHistory(id);
      synced++;
      if (synced % 20 === 0) log(`  synced ${synced}…`);
    } catch (err) {
      log(`  player ${id} failed: ${(err as Error).message}`);
    }
  }
  log(`  Synced ${synced}, skipped ${skipped} already-present.`);
  return synced;
}

async function cumulativePointsAtGw(playerId: number, gw: number): Promise<number> {
  const rows = await prisma.pointSnapshot.findMany({
    where: { playerId, gameweek: { lte: gw } },
    select: { points: true },
  });
  return rows.reduce((s, r) => s + r.points, 0);
}

type SwapTarget = {
  player: P;
  recent: number;
  cumulative: number;
  bidAmount: number;
  auctionBoost: number;
};

type SwapIntent = {
  managerId: number;
  managerTeam: string;
  worst: {
    entryId: number;
    playerId: number;
    pos: number;
    slot: number | null;
    bid: number;
    pointsToDate: number;
    lastGwPts: number;
    webName: string;
    sellPrice: number;
  };
  freeBalance: number;
  targets: SwapTarget[];
};

// Compute the manager's intent for the gameweek — who to sell, which targets
// to bid on (ranked), and how much. No DB writes. Used by the auction
// orchestrator in simulateSeason.
async function prepareSwapIntent(
  managerId: number,
  managerTeam: string,
  pool: P[],
  swapAt: Date,
  gw: number,
  rand: () => number,
  ownedByOthers: Set<number>,
): Promise<SwapIntent | null> {
  const starters = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER, playing: true },
    include: { player: true },
  });
  if (starters.length === 0) return null;

  // Score each starter: cumulative pts to date AND points in the latest GW
  // (so we can spot likely-injured 0-scorers).
  const scored: Array<{
    entryId: number;
    playerId: number;
    pos: number;
    slot: number | null;
    bid: number;
    pointsToDate: number;
    lastGwPts: number;
    webName: string;
  }> = [];
  for (const s of starters) {
    const pts = await cumulativePointsAtGw(s.playerId, gw);
    const latest = await prisma.pointSnapshot.findFirst({
      where: { playerId: s.playerId, gameweek: gw },
      select: { points: true },
    });
    scored.push({
      entryId: s.id,
      playerId: s.playerId,
      pos: s.player.position,
      slot: s.formationSlot,
      bid: s.bid,
      pointsToDate: pts,
      lastGwPts: latest?.points ?? 0,
      webName: s.player.webName,
    });
  }
  // Priority sell: starters who scored 0 in the latest GW are treated as
  // likely injured. Among those, pick the most expensive (biggest
  // disappointment to dump). Otherwise fall back to worst cumulative.
  const zeroScorers = scored.filter((s) => s.lastGwPts === 0);
  let worst;
  if (zeroScorers.length > 0) {
    zeroScorers.sort((a, b) => b.bid - a.bid);
    worst = zeroScorers[0]!;
  } else {
    scored.sort((a, b) => a.pointsToDate - b.pointsToDate);
    worst = scored[0]!;
  }

  // Compute the worst player's sale-time book price up-front so the budget
  // math can account for the realised loss (bid − sellPrice).
  const worstValueSnap = await prisma.pointSnapshot.findFirst({
    where: { playerId: worst.playerId, gameweek: gw },
    select: { value: true },
  });
  const worstNowCostRow = await prisma.player.findUnique({
    where: { id: worst.playerId },
    select: { nowCost: true },
  });
  const worstSellPrice =
    (worstValueSnap?.value ?? worstNowCostRow?.nowCost ?? 0) / 10;

  // Budget: sum of active bids (money tied up) + realised losses from past
  // sells (bid − sellPrice for closed entries). After this sell the freed
  // amount is worstSellPrice, not the original bid.
  const activeEntries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER },
  });
  const soldEntries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: { lt: FOREVER } },
    select: { bid: true, sellPrice: true },
  });
  const activeSpent = activeEntries.reduce((s, e) => s + e.bid, 0);
  const pastLosses = soldEntries.reduce(
    (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
    0,
  );
  const freeBalance = BUDGET - activeSpent - pastLosses + worstSellPrice;

  // Candidate replacements: same position, not currently owned by another
  // manager, affordable. (worst is "owned by self" but we ARE selling them,
  // so even if they're in ownedByOthers from an earlier scan we skip them.)
  const candidatesPool = pool.filter(
    (p) =>
      p.position === worst.pos &&
      !ownedByOthers.has(p.id) &&
      p.id !== worst.playerId &&
      p.nowCost / 10 <= freeBalance,
  );
  if (candidatesPool.length === 0) return null;

  // Score by *recent* form (last 5 GWs) + a quarter of cumulative — mirrors
  // how a real manager picks: hot players first, with season totals breaking
  // ties. Look at the top 40 affordable candidates by end-of-season totals
  // so we don't have to score every player in the league.
  const scoredCandidates: Array<{ player: P; recent: number; cumulative: number; score: number }> = [];
  for (const c of candidatesPool.slice(0, 40)) {
    const cumulative = await cumulativePointsAtGw(c.id, gw);
    const recentLo = Math.max(1, gw - 4);
    const recentRows = await prisma.pointSnapshot.findMany({
      where: { playerId: c.id, gameweek: { gte: recentLo, lte: gw } },
      select: { points: true },
    });
    const recent = recentRows.reduce((s, r) => s + r.points, 0);
    scoredCandidates.push({
      player: c,
      recent,
      cumulative,
      score: recent + cumulative / 4,
    });
  }
  if (scoredCandidates.length === 0) return null;
  scoredCandidates.sort((a, b) => b.score - a.score);

  // Top 5 candidates ranked by score. We'll shuffle slightly so each manager
  // can express a different preference order and not always converge on the
  // same #1 pick — gives the auction more variety.
  const top = scoredCandidates.slice(0, 5);
  for (let i = top.length - 1; i > 0; i--) {
    if (rand() < 0.35) {
      const j = Math.floor(rand() * (i + 1));
      [top[i], top[j]] = [top[j]!, top[i]!];
    }
  }

  // Compute a bid amount for each target — premium tier + random boost +
  // optional auction premium if the player was recently sold and is scoring
  // again. Capped to freeBalance so we never over-spend.
  const fourWeeksAgo = new Date(swapAt.getTime() - 4 * 7 * 24 * 60 * 60 * 1000);
  const targets: SwapTarget[] = [];
  for (const c of top) {
    const book = c.player.nowCost / 10;
    let premium = 0.75;
    if (c.cumulative >= 150) premium = 4.0;
    else if (c.cumulative >= 100) premium = 3.0;
    else if (c.cumulative >= 50) premium = 1.5;
    const boost = rand() * premium * 1.5;

    const wasRecentlySold = await prisma.squadEntry.findFirst({
      where: {
        playerId: c.player.id,
        untilAt: { gt: fourWeeksAgo, lt: FOREVER },
      },
      select: { id: true },
    });
    let auctionBoost = 0;
    if (wasRecentlySold && c.recent > 0) {
      auctionBoost = rand() * 3.0;
    }
    const bidAmount = Math.min(book + premium + boost + auctionBoost, freeBalance);
    targets.push({
      player: c.player,
      recent: c.recent,
      cumulative: c.cumulative,
      bidAmount,
      auctionBoost,
    });
  }

  return {
    managerId,
    managerTeam,
    worst: { ...worst, sellPrice: worstSellPrice },
    freeBalance,
    targets,
  };
}

// Commit a winning auction: sell the manager's worst, buy the chosen player,
// record the winning bid + Signed/Sold paper-talks.
async function applySwap(
  intent: SwapIntent,
  target: SwapTarget,
  swapAt: Date,
  log: Log,
  outbid: number,
): Promise<void> {
  const placedAt = new Date(swapAt.getTime() - 7 * 60 * 60 * 1000);
  const worst = intent.worst;

  await prisma.$transaction(async (tx) => {
    await tx.squadEntry.update({
      where: { id: worst.entryId },
      data: {
        untilAt: swapAt,
        playing: false,
        formationSlot: null,
        sellPrice: worst.sellPrice,
      },
    });
    await tx.bid.create({
      data: {
        managerId: intent.managerId,
        playerId: target.player.id,
        amount: target.bidAmount,
        placedAt,
        resolved: true,
        won: true,
      },
    });
    await tx.squadEntry.create({
      data: {
        managerId: intent.managerId,
        playerId: target.player.id,
        bid: target.bidAmount,
        fromAt: swapAt,
        untilAt: FOREVER,
        playing: true,
        formationSlot: worst.slot,
      },
    });
    const oldPlayer = await tx.player.findUnique({
      where: { id: worst.playerId },
      include: { team: true },
    });
    const newPlayer = await tx.player.findUnique({
      where: { id: target.player.id },
      include: { team: true },
    });
    await tx.paperTalk.create({
      data: {
        when: swapAt,
        managerId: intent.managerId,
        teamName: oldPlayer?.team.name ?? null,
        playerName: oldPlayer?.webName ?? worst.webName,
        reason: worst.lastGwPts === 0 ? "Sold (likely injured)" : "Sold",
        bid: worst.sellPrice,
      },
    });
    await tx.paperTalk.create({
      data: {
        when: swapAt,
        managerId: intent.managerId,
        teamName: newPlayer?.team.name ?? null,
        playerName: newPlayer?.webName ?? target.player.webName,
        reason: outbid > 0 ? `Signed (outbid ${outbid} rival${outbid === 1 ? "" : "s"})` : "Signed",
        bid: target.bidAmount,
      },
    });
  });

  const tag = worst.lastGwPts === 0 ? "INJ" : "POOR";
  const auctionTag = target.auctionBoost > 0 ? " [auction]" : "";
  const contestTag = outbid > 0 ? ` [beat ${outbid}]` : "";
  log(
    `    ${tag}: ${worst.webName} (last ${worst.lastGwPts}, cum ${worst.pointsToDate}, £${worst.bid.toFixed(1)}m) → ${target.player.webName} (recent ${target.recent}, cum ${target.cumulative}, bid £${target.bidAmount.toFixed(1)}m)${auctionTag}${contestTag}`,
  );
}

// Record a losing bid: stamp it as resolved-but-lost and add an Outbid
// paper-talk so the bidder's history reflects the contested attempt.
async function recordLosingBid(
  intent: SwapIntent,
  target: SwapTarget,
  swapAt: Date,
  winnerTeam: string,
): Promise<void> {
  const placedAt = new Date(swapAt.getTime() - 7 * 60 * 60 * 1000);
  await prisma.bid.create({
    data: {
      managerId: intent.managerId,
      playerId: target.player.id,
      amount: target.bidAmount,
      placedAt,
      resolved: true,
      won: false,
    },
  });
  const player = await prisma.player.findUnique({
    where: { id: target.player.id },
    include: { team: true },
  });
  await prisma.paperTalk.create({
    data: {
      when: swapAt,
      managerId: intent.managerId,
      teamName: player?.team.name ?? null,
      playerName: player?.webName ?? target.player.webName,
      reason: `Outbid by ${winnerTeam}`,
      bid: target.bidAmount,
    },
  });
}

async function gwKickoffDates(): Promise<Map<number, Date>> {
  // Use median kickoffTime per gameweek across all snapshots we've already
  // synced for owned players. Good enough to time weekly swaps with the season.
  const rows = await prisma.pointSnapshot.findMany({
    where: { kickoffTime: { not: null } },
    select: { gameweek: true, kickoffTime: true },
  });
  const byGw = new Map<number, Date[]>();
  for (const r of rows) {
    if (!r.kickoffTime) continue;
    const list = byGw.get(r.gameweek) ?? [];
    list.push(r.kickoffTime);
    byGw.set(r.gameweek, list);
  }
  const out = new Map<number, Date>();
  for (const [gw, dates] of byGw) {
    dates.sort((a, b) => a.getTime() - b.getTime());
    const mid = dates[Math.floor(dates.length / 2)];
    out.set(gw, mid);
  }
  return out;
}

async function simulateSeason(managerIds: number[], log: Log): Promise<number> {
  log("Loading player pool for in-season decisions…");
  const pool = await loadPool();

  log("Computing gameweek timing from synced histories…");
  const kickoffs = await gwKickoffDates();
  if (kickoffs.size === 0) {
    log("  no gameweek data found — cannot simulate weekly swaps.");
    return 0;
  }

  const rand = rng(2026);
  let totalSwaps = 0;
  let totalContestedAuctions = 0;
  let totalOutbids = 0;

  // Cache manager team names so log lines are readable.
  const teamByManager = new Map<number, string>();
  const managers = await prisma.manager.findMany({
    where: { id: { in: managerIds } },
    select: { id: true, teamName: true },
  });
  for (const m of managers) teamByManager.set(m.id, m.teamName);

  for (let gw = 2; gw <= 38; gw++) {
    const kickoff = kickoffs.get(gw);
    if (!kickoff) continue;
    const day = new Date(kickoff);
    day.setUTCHours(1, 0, 0, 0);
    day.setUTCDate(day.getUTCDate() - 1);
    if (day < SEASON_START || day > SEASON_END) continue;

    // Phase 1: every manager prepares a swap intent (worst + top 5 ranked
    // targets with their max bids). Process the prepare in random order so
    // the "claimed" pool snapshot is the same for everyone (we pass it in
    // explicitly, captured once before any apply happens).
    const claimedRows = await prisma.squadEntry.findMany({
      where: { untilAt: FOREVER },
      select: { playerId: true },
    });
    const initiallyClaimed = new Set(claimedRows.map((c) => c.playerId));

    const intents: SwapIntent[] = [];
    for (const mid of managerIds) {
      const team = teamByManager.get(mid) ?? "?";
      // Players claimed by OTHERS — we exclude them as targets. Each
      // manager's own players are valid candidates only if we're selling
      // them (worst), which prepareSwapIntent handles.
      const ownerEntries = await prisma.squadEntry.findMany({
        where: { managerId: { not: mid }, untilAt: FOREVER },
        select: { playerId: true },
      });
      const ownedByOthers = new Set(ownerEntries.map((e) => e.playerId));
      const intent = await prepareSwapIntent(mid, team, pool, day, gw - 1, rand, ownedByOthers);
      if (intent && intent.targets.length > 0) intents.push(intent);
    }

    if (intents.length === 0) continue;

    // Phase 2: resolve auctions in up to 3 rounds. Each round, every
    // remaining intent nominates their next-best target that hasn't been
    // won yet this gameweek. Collisions → highest bid wins; losers retry
    // the next round with their next preference.
    const wonThisGw = new Set<number>(initiallyClaimed);
    let remaining = intents;
    let round = 0;
    let gwSwaps = 0;
    let gwContested = 0;
    let gwOutbids = 0;
    while (remaining.length > 0 && round < 3) {
      round++;
      // Map each intent to its highest-priority unowned target this round.
      const nominations: Array<{ intent: SwapIntent; target: SwapTarget }> = [];
      const noChoice: SwapIntent[] = [];
      for (const intent of remaining) {
        const target = intent.targets.find((t) => !wonThisGw.has(t.player.id));
        if (target) nominations.push({ intent, target });
        else noChoice.push(intent);
      }

      // Group nominations by target playerId.
      const byTarget = new Map<number, Array<{ intent: SwapIntent; target: SwapTarget }>>();
      for (const nom of nominations) {
        const list = byTarget.get(nom.target.player.id) ?? [];
        list.push(nom);
        byTarget.set(nom.target.player.id, list);
      }

      const nextLosers: SwapIntent[] = [];
      for (const [playerId, contestants] of byTarget) {
        contestants.sort((a, b) => b.target.bidAmount - a.target.bidAmount);
        const winner = contestants[0]!;
        const losers = contestants.slice(1);
        await applySwap(winner.intent, winner.target, day, log, losers.length);
        wonThisGw.add(playerId);
        gwSwaps++;
        if (losers.length > 0) {
          gwContested++;
          gwOutbids += losers.length;
          for (const l of losers) {
            await recordLosingBid(l.intent, l.target, day, winner.intent.managerTeam);
            nextLosers.push(l.intent);
          }
        }
      }

      remaining = nextLosers;
      // noChoice (intents with no remaining unwon targets) drop silently.
    }

    totalSwaps += gwSwaps;
    totalContestedAuctions += gwContested;
    totalOutbids += gwOutbids;
    log(
      `GW${gw} (${day.toISOString().slice(0, 10)} 01:00): ${gwSwaps} swaps · ${gwContested} contested auctions · ${gwOutbids} outbids`,
    );
  }

  log(
    `Season totals: ${totalSwaps} swaps, ${totalContestedAuctions} contested auctions, ${totalOutbids} outbids.`,
  );
  return totalSwaps;
}

async function verifyIntegrity(log: Log): Promise<void> {
  log("");
  log("Integrity checks:");
  const managers = await prisma.manager.findMany({ select: { id: true, teamName: true } });
  let failures = 0;
  for (const m of managers) {
    const entries = await prisma.squadEntry.findMany({
      where: { managerId: m.id, untilAt: FOREVER },
    });
    const playing = entries.filter((e) => e.playing).length;
    const benched = entries.filter((e) => !e.playing).length;
    const slots = new Set(entries.filter((e) => e.playing).map((e) => e.formationSlot));
    const expectedBench = entries.length - 11;
    const ok =
      entries.length >= SQUAD_MIN &&
      entries.length <= SQUAD_TARGET &&
      playing === 11 &&
      benched === expectedBench &&
      slots.size === 11 &&
      !slots.has(null);
    if (!ok) {
      failures++;
      log(
        `  ✗ ${m.teamName.padEnd(22)}  total=${entries.length} playing=${playing} bench=${benched} unique_slots=${slots.size}`,
      );
    }
  }
  if (failures === 0) {
    log(`  ✓ all ${managers.length} managers have ${SQUAD_MIN}..${SQUAD_TARGET} players (11 in XI, remainder bench, slots 0..10).`);
  }

  // Budget invariant: BUDGET − active_spent − realised_losses ≥ 0 for every
  // manager. If any goes negative, the sim has spent money it didn't have.
  let overspent = 0;
  for (const m of managers) {
    const active = await prisma.squadEntry.findMany({
      where: { managerId: m.id, untilAt: FOREVER },
    });
    const sold = await prisma.squadEntry.findMany({
      where: { managerId: m.id, untilAt: { lt: FOREVER } },
      select: { bid: true, sellPrice: true },
    });
    const activeSpent = active.reduce((s, e) => s + e.bid, 0);
    const realisedLosses = sold.reduce(
      (s, e) => s + (e.bid - (e.sellPrice ?? e.bid)),
      0,
    );
    const balance = BUDGET - activeSpent - realisedLosses;
    if (balance < -1e-6) {
      overspent++;
      log(
        `  ✗ ${m.teamName.padEnd(22)} balance=£${balance.toFixed(2)}m (spent=£${activeSpent.toFixed(1)}m, losses=£${realisedLosses.toFixed(1)}m)`,
      );
    }
  }
  if (overspent === 0) {
    log(`  ✓ no manager has overspent — BUDGET − spent − losses ≥ 0 for all ${managers.length}.`);
  }

  // Verify benched/sold players score zero: compare standings query to the
  // sum across *all* owned snapshots regardless of playing/sold. The
  // standings number should always be ≤ the all-included number, and the
  // gap is exactly the bench+sold contribution.
  const standingsRows = await prisma.$queryRawUnsafe<{ id: number; score: number }[]>(`
    SELECT m.id, COALESCE(SUM(ps.points), 0) AS score
    FROM Manager m
    LEFT JOIN SquadEntry se ON se.managerId = m.id AND se.playing = 1
    LEFT JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
      AND ps.kickoffTime IS NOT NULL
      AND ps.kickoffTime >= se.fromAt
      AND ps.kickoffTime < se.untilAt
    GROUP BY m.id
  `);
  const allRows = await prisma.$queryRawUnsafe<{ id: number; score: number }[]>(`
    SELECT m.id, COALESCE(SUM(ps.points), 0) AS score
    FROM Manager m
    LEFT JOIN SquadEntry se ON se.managerId = m.id
    LEFT JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
      AND ps.kickoffTime IS NOT NULL
      AND ps.kickoffTime >= se.fromAt
      AND ps.kickoffTime < se.untilAt
    GROUP BY m.id
  `);
  // Bench + sold = playing=0 (we set playing=false on every sell).
  const benchSoldRows = await prisma.$queryRawUnsafe<{ id: number; score: number }[]>(`
    SELECT m.id, COALESCE(SUM(ps.points), 0) AS score
    FROM Manager m
    LEFT JOIN SquadEntry se ON se.managerId = m.id AND se.playing = 0
    LEFT JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
      AND ps.kickoffTime IS NOT NULL
      AND ps.kickoffTime >= se.fromAt
      AND ps.kickoffTime < se.untilAt
    GROUP BY m.id
  `);
  let imbalance = 0;
  for (const r of standingsRows) {
    const all = Number(allRows.find((x) => x.id === r.id)?.score ?? 0);
    const off = Number(benchSoldRows.find((x) => x.id === r.id)?.score ?? 0);
    const playing = Number(r.score);
    if (playing + off !== all) {
      imbalance++;
      log(
        `  ✗ manager #${r.id}: playing(${playing}) + off(${off}) != all(${all})`,
      );
    }
  }
  if (imbalance === 0) {
    log(`  ✓ for every manager, standings = sum of playing-true ownership windows.`);
    log(`  ✓ bench + sold points are excluded from standings.`);
  }
  const totalOff = benchSoldRows.reduce((s, r) => s + Number(r.score), 0);
  log(`  Total points belonging to bench/sold players across all managers: ${totalOff} (correctly excluded from standings).`);
}

async function showStandings(log: Log): Promise<void> {
  type Row = {
    managerId: number;
    teamName: string;
    score: number | null;
  };
  const rows = await prisma.$queryRawUnsafe<Row[]>(`
    SELECT
      m.id AS managerId,
      m.teamName AS teamName,
      COALESCE(SUM(ps.points), 0) AS score
    FROM Manager m
    LEFT JOIN SquadEntry se ON se.managerId = m.id AND se.playing = 1
    LEFT JOIN PointSnapshot ps
      ON ps.playerId = se.playerId
      AND ps.kickoffTime IS NOT NULL
      AND ps.kickoffTime >= se.fromAt
      AND ps.kickoffTime < se.untilAt
    GROUP BY m.id, m.teamName
    ORDER BY score DESC, m.teamName ASC
  `);
  log("");
  log("Final standings:");
  rows.forEach((r, i) => {
    log(`  ${(i + 1).toString().padStart(2)}.  ${r.teamName.padEnd(22)}  ${Number(r.score ?? 0)} pts`);
  });
}

export async function runFullSimulation(log: Log = console.log): Promise<void> {
  await wipeAll(log);
  await resyncFpl(log);

  log("Loading player pool…");
  const pool = await loadPool();
  log(`  ${pool.length} eligible players`);

  // With £150m and 20 players (~£7.5m avg) we leave ~£15m headroom so
  // mid-season swaps can pay realistic premiums plus random boost.
  const { managerIds } = await seedInitialSquads(pool, log, BUDGET * 10 - 150);
  // Initial history sync so we have GW timing + per-GW points for decisions.
  await syncHistoriesForOwned(log);

  const swaps = await simulateSeason(managerIds, log);
  log(`Total in-season swaps: ${swaps}`);

  // After swaps, the newly-bought players may not yet have their histories.
  await syncHistoriesForOwned(log);

  await verifyIntegrity(log);
  await showStandings(log);
  log("");
  log("Simulation complete.");
}

// CLI entry-point
const invokedAsScript =
  import.meta.url.startsWith("file:") &&
  process.argv[1] &&
  import.meta.url === new URL(`file:///${process.argv[1].replaceAll("\\", "/")}`).href;

if (invokedAsScript) {
  runFullSimulation()
    .then(async () => {
      await prisma.$disconnect();
    })
    .catch(async (err) => {
      console.error(err);
      await prisma.$disconnect();
      process.exit(1);
    });
}
