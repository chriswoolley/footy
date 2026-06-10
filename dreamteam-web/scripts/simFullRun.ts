/**
 * Full end-to-end simulation + verification.
 *
 * Runs INSIDE the container so it can both call the real HTTP API (localhost:3000)
 * and read/write the same SQLite DB via Prisma.
 *
 *   - 20 game players (managers); CWoolley is also the admin who runs bid resolution.
 *   - Each targets a 15-20 player squad with a valid 4-4-2 composition.
 *   - Bidding runs in cycles (the "every 2 minutes" cadence, compressed here):
 *       every cycle each manager places real bids via POST /api/bids, then the
 *       admin resolves them via POST /api/admin/run-bids. Loops until every
 *       manager has reached its target (or can no longer progress).
 *   - Synthetic match data: 11 players per team per "match" (gameweek) get points.
 *   - Each manager's 4-4-2 XI is selected (best scorers).
 *   - VERIFY: app standings == independent recompute; bidding invariants hold;
 *     contested players were won by the highest bid.
 */
import { PrismaClient } from "@prisma/client";

const BASE = "http://localhost:3000";
const prisma = new PrismaClient();
const FOREVER = new Date("9999-12-31T00:00:00Z");
const BUDGET = Number(process.env.BUDGET ?? 150);
const MAX_SQUAD = 20;
const N_PLAYERS = 20; // game players
const GAMEWEEKS = 6; // synthetic "matches"
const MAX_CYCLES = 60;
const BIDS_PER_CYCLE = 3;
const POS_NAMES = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

// Deterministic PRNG.
let seed = 20260610;
const rand = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 0xffffffff);

// ── HTTP helper with per-manager cookie ──────────────────────────────────────
function tokenFrom(res: Response): string {
  const all = (res.headers as any).getSetCookie?.() ?? [res.headers.get("set-cookie")];
  for (const c of all) {
    const m = c && /dt_token=[^;]+/.exec(c);
    if (m) return m[0];
  }
  return "";
}
async function api(
  path: string,
  opts: { method?: string; body?: unknown; cookie?: string } = {},
): Promise<{ status: number; json: any; res: Response }> {
  const res = await fetch(BASE + path, {
    method: opts.method ?? "GET",
    headers: {
      "content-type": "application/json",
      ...(opts.cookie ? { cookie: opts.cookie } : {}),
    },
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });
  let json: any = null;
  const text = await res.text();
  try {
    json = JSON.parse(text);
  } catch {
    json = text;
  }
  return { status: res.status, json, res };
}

type Mgr = {
  username: string;
  teamName: string;
  cookie: string;
  id: number;
  target: number;
  comp: Record<number, number>;
  stalled: number;
  done: boolean;
};

// Composition for a target T (15-20): 2 GK, then 5/5/3 baseline, extras to DEF/MID/FWD.
function compositionFor(target: number): Record<number, number> {
  const comp: Record<number, number> = { 1: 2, 2: 5, 3: 5, 4: 3 }; // = 15
  let extra = target - 15;
  const order = [2, 3, 4];
  let i = 0;
  while (extra > 0) {
    comp[order[i % order.length]]++;
    extra--;
    i++;
  }
  return comp;
}

async function activeCounts(managerId: number): Promise<Record<number, number>> {
  const entries = await prisma.squadEntry.findMany({
    where: { managerId, untilAt: FOREVER },
    include: { player: { select: { position: true } } },
  });
  const c: Record<number, number> = { 1: 0, 2: 0, 3: 0, 4: 0 };
  for (const e of entries) c[e.player.position]++;
  return c;
}
async function activeSpent(managerId: number): Promise<number> {
  const e = await prisma.squadEntry.findMany({ where: { managerId, untilAt: FOREVER } });
  return e.reduce((s, x) => s + x.bid, 0);
}
async function ownedPlayerIds(): Promise<Set<number>> {
  const e = await prisma.squadEntry.findMany({
    where: { untilAt: FOREVER },
    select: { playerId: true },
  });
  return new Set(e.map((x) => x.playerId));
}

// ── 0. RESET ─────────────────────────────────────────────────────────────────
console.log("[sim] resetting managers / bids / squads / snapshots");
await prisma.$transaction([
  prisma.bid.deleteMany({}),
  prisma.pendingChange.deleteMany({}),
  prisma.paperTalk.deleteMany({}),
  prisma.squadEntry.deleteMany({}),
  prisma.manager.deleteMany({}),
  prisma.pointSnapshot.deleteMany({}),
  prisma.audit.deleteMany({}),
]);

// ── 1. REGISTER 20 game players (CWoolley = admin) ───────────────────────────
const usernames = ["CWoolley", ...Array.from({ length: N_PLAYERS - 1 }, (_, i) => `gp${i + 2}`)];
const mgrs: Mgr[] = [];
for (const username of usernames) {
  const teamName = `${username} FC`;
  const r = await api("/api/auth/register", {
    method: "POST",
    body: { username, password: "sim-pass", teamName },
  });
  if (r.status !== 200) throw new Error(`register ${username} failed: ${JSON.stringify(r.json)}`);
  const target = 15 + Math.floor(rand() * 6); // 15..20
  mgrs.push({
    username,
    teamName,
    cookie: tokenFrom(r.res),
    id: r.json.id,
    target,
    comp: compositionFor(target),
    stalled: 0,
    done: false,
  });
}
const admin = mgrs[0]; // CWoolley
console.log(`[sim] registered ${mgrs.length} managers; targets: ${mgrs.map((m) => m.target).join(",")}`);

// ── 2. BIDDING CYCLES (the every-2-min cadence, compressed) ──────────────────
type Contest = { player: number; cycle: number; bids: { mgr: number; amount: number }[]; expectedWinner: number };
const contests: Contest[] = [];
let totalPlaced = 0;
let totalWon = 0;

for (let cycle = 1; cycle <= MAX_CYCLES; cycle++) {
  if (mgrs.every((m) => m.done)) break;
  const owned = await ownedPlayerIds();

  // Each manager places up to BIDS_PER_CYCLE bids toward its composition.
  for (const m of mgrs) {
    if (m.done) continue;
    const counts = await activeCounts(m.id);
    const total = counts[1] + counts[2] + counts[3] + counts[4];
    if (total >= m.target) {
      m.done = true;
      continue;
    }
    const spent = await activeSpent(m.id);
    let budgetLeft = BUDGET - spent;
    let placed = 0;
    const bidThisCycle = new Set<number>();

    for (const pos of [2, 3, 4, 1]) {
      if (placed >= BIDS_PER_CYCLE) break;
      if (counts[pos] >= m.comp[pos]) continue;
      // Cheapest unowned players of this position; spread the pick across
      // managers so squads fill while still colliding (contested auctions).
      const pool = await prisma.player.findMany({
        where: { position: pos, status: "a", id: { notIn: Array.from(owned) } },
        orderBy: [{ nowCost: "asc" }, { totalPoints: "desc" }, { id: "asc" }],
        take: 80,
        select: { id: true, nowCost: true },
      });
      const candidates = pool.filter((p) => !bidThisCycle.has(p.id));
      if (candidates.length === 0) continue;
      const offset = (mgrs.indexOf(m) * 2 + cycle) % candidates.length;
      const pick = candidates[offset];
      const book = pick.nowCost / 10;
      // ~35% of bids add a premium so contests have a clear highest bidder
      // (and to exercise over-book bidding against the larger budget).
      const premium = rand() < 0.35 ? Math.round(rand() * 60) / 10 : 0;
      const amount = Math.round((book + premium) * 10) / 10;
      if (amount > budgetLeft + 1e-9) continue;

      const r = await api("/api/bids", {
        method: "POST",
        cookie: m.cookie,
        body: { playerId: pick.id, amount },
      });
      if (r.status === 200) {
        budgetLeft -= amount;
        placed++;
        totalPlaced++;
        bidThisCycle.add(pick.id);
      }
    }
    if (placed === 0) {
      m.stalled++;
      if (m.stalled >= 3) m.done = true; // can't progress; stop
    } else {
      m.stalled = 0;
    }
  }

  // Inject deliberate contested auctions to exercise highest-bid-wins. Several
  // managers bid the SAME (fresh, mid-priced) player with distinct, descending
  // premiums, so the first bidder should win unless budget/cap-skipped.
  if (cycle <= 6) {
    const elig = mgrs.filter((m) => !m.done);
    const ownedNow = Array.from(await ownedPlayerIds());
    for (let c = 0; c < 2 && elig.length >= 3; c++) {
      const pool = await prisma.player.findMany({
        where: { position: 2, status: "a", id: { notIn: ownedNow } },
        orderBy: [{ nowCost: "asc" }],
        skip: 100 + c * 12,
        take: 1,
        select: { id: true, nowCost: true },
      });
      if (pool.length === 0) continue;
      const target = pool[0];
      const book = target.nowCost / 10;
      const premiums = [8, 5, 3, 1]; // descending -> first bidder is the highest
      const group: Mgr[] = [];
      for (let k = 0; group.length < 4 && k < elig.length * 2; k++) {
        const m = elig[(cycle * 3 + c * 5 + k) % elig.length];
        if (!group.includes(m)) group.push(m);
      }
      for (let k = 0; k < group.length; k++) {
        const m = group[k];
        const amount = Math.round((book + premiums[k]) * 10) / 10;
        if ((await activeSpent(m.id)) + amount > BUDGET) continue;
        const r = await api("/api/bids", {
          method: "POST",
          cookie: m.cookie,
          body: { playerId: target.id, amount },
        });
        if (r.status === 200) totalPlaced++;
      }
    }
  }

  // Snapshot the pending bids (for contest verification) then resolve via the API.
  const pending = await prisma.bid.findMany({
    where: { resolved: false },
    orderBy: [{ amount: "desc" }, { placedAt: "asc" }],
  });
  const byPlayer = new Map<number, typeof pending>();
  for (const b of pending) {
    const l = byPlayer.get(b.playerId) ?? [];
    l.push(b);
    byPlayer.set(b.playerId, l);
  }
  for (const [player, bids] of byPlayer) {
    if (bids.length > 1) {
      // highest amount, tie → earliest placedAt (already sorted that way)
      contests.push({
        player,
        cycle,
        bids: bids.map((b) => ({ mgr: b.managerId, amount: b.amount })),
        expectedWinner: bids[0].managerId,
      });
    }
  }

  const run = await api("/api/admin/run-bids", { method: "POST", cookie: admin.cookie });
  if (run.status !== 200) throw new Error(`run-bids failed: ${JSON.stringify(run.json)}`);
  totalWon += run.json.won ?? 0;

  const sizes = await Promise.all(
    mgrs.map((m) => prisma.squadEntry.count({ where: { managerId: m.id, untilAt: FOREVER } })),
  );
  const doneN = mgrs.filter((m) => m.done).length;
  if (cycle % 5 === 0 || doneN === mgrs.length) {
    console.log(
      `[sim] cycle ${cycle}: won=${run.json.won} done=${doneN}/${mgrs.length} sizes=[${sizes.join(",")}]`,
    );
  }
}

// ── 3. SELECT 4-4-2 XI (best scorers) ────────────────────────────────────────
const XI = { 1: 1, 2: 4, 3: 4, 4: 2 } as const;
const slotBase: Record<number, number> = { 1: 0, 2: 1, 3: 5, 4: 9 };
for (const m of mgrs) {
  await prisma.squadEntry.updateMany({
    where: { managerId: m.id, untilAt: FOREVER },
    data: { playing: false, formationSlot: null },
  });
  const entries = await prisma.squadEntry.findMany({
    where: { managerId: m.id, untilAt: FOREVER },
    include: { player: { select: { position: true, totalPoints: true } } },
  });
  const byPos: Record<number, typeof entries> = { 1: [], 2: [], 3: [], 4: [] };
  for (const e of entries) byPos[e.player.position].push(e);
  for (const pos of [1, 2, 3, 4]) {
    byPos[pos].sort((a, b) => b.player.totalPoints - a.player.totalPoints);
    const need = XI[pos as 1 | 2 | 3 | 4];
    for (let i = 0; i < need && i < byPos[pos].length; i++) {
      await prisma.squadEntry.update({
        where: { id: byPos[pos][i].id },
        data: { playing: true, formationSlot: slotBase[pos] + i },
      });
    }
  }
}

// ── 4. SYNTHETIC MATCH DATA: 11 players per team per gameweek ────────────────
const base = Date.now(); // all kickoffs after this -> within every ownership window
const teams = await prisma.team.findMany({ select: { id: true } });
let snapshots = 0;
for (const t of teams) {
  const squad = await prisma.player.findMany({
    where: { teamId: t.id, status: "a" },
    orderBy: [{ totalPoints: "desc" }, { id: "asc" }],
    take: 11, // the "starting 11" that play each match
    select: { id: true, nowCost: true },
  });
  for (let gw = 1; gw <= GAMEWEEKS; gw++) {
    const kickoff = new Date(base + gw * 3_600_000);
    for (const p of squad) {
      const points = 1 + ((p.id * 7 + gw * 3) % 12); // deterministic 1..12
      await prisma.pointSnapshot.create({
        data: { playerId: p.id, gameweek: gw, points, value: p.nowCost, kickoffTime: kickoff },
      });
      snapshots++;
    }
  }
}
console.log(`[sim] generated ${snapshots} point snapshots (${GAMEWEEKS} GWs × 11 per team)`);

// ── 5. VERIFICATION ──────────────────────────────────────────────────────────
console.log("\n========== VERIFICATION ==========");
let failures = 0;
const fail = (msg: string) => {
  failures++;
  console.log(`  ❌ ${msg}`);
};

// 5a. Bidding invariants
const allActive = await prisma.squadEntry.findMany({
  where: { untilAt: FOREVER },
  select: { managerId: true, playerId: true, bid: true },
});
const ownerByPlayer = new Map<number, number>();
let dupOwn = 0;
for (const e of allActive) {
  if (ownerByPlayer.has(e.playerId)) dupOwn++;
  else ownerByPlayer.set(e.playerId, e.managerId);
}
if (dupOwn === 0) console.log(`  ✅ player ownership unique (${allActive.length} active entries, no player owned twice)`);
else fail(`${dupOwn} players owned by more than one manager`);

let overBudget = 0,
  overCap = 0;
for (const m of mgrs) {
  const es = allActive.filter((e) => e.managerId === m.id);
  const spent = es.reduce((s, e) => s + e.bid, 0);
  if (spent > BUDGET + 1e-6) overBudget++;
  if (es.length > MAX_SQUAD) overCap++;
}
if (overBudget === 0) console.log(`  ✅ no manager exceeded £${BUDGET}m budget`);
else fail(`${overBudget} managers exceeded budget`);
if (overCap === 0) console.log(`  ✅ no manager exceeded ${MAX_SQUAD}-player cap`);
else fail(`${overCap} managers exceeded squad cap`);

// 5b. Contested auctions resolved to the highest bid
let contestPass = 0,
  contestFail = 0;
for (const c of contests) {
  const owner = ownerByPlayer.get(c.player);
  // The expected winner only actually wins if it didn't bust budget/cap at
  // resolution time; if owner is undefined or someone else due to that, only
  // flag a failure when the owner is a LOWER bidder than the expected winner.
  if (owner === c.expectedWinner) contestPass++;
  else {
    const ownerBid = c.bids.find((b) => b.mgr === owner)?.amount ?? -1;
    const maxBid = Math.max(...c.bids.map((b) => b.amount));
    if (owner != null && ownerBid < maxBid - 1e-9) contestFail++;
    else contestPass++; // expected winner was budget/cap-skipped; acceptable
  }
}
if (contestFail === 0)
  console.log(`  ✅ contested auctions: ${contestPass}/${contests.length} resolved to highest eligible bid`);
else fail(`${contestFail} contested players NOT won by the highest bidder`);

// 5c. Squad-size targets (15-20 or stalled-out)
const sizeRows = await Promise.all(
  mgrs.map(async (m) => ({
    m,
    size: await prisma.squadEntry.count({ where: { managerId: m.id, untilAt: FOREVER } }),
  })),
);
const inRange = sizeRows.filter((r) => r.size >= 15 && r.size <= 20).length;
console.log(
  `  ${inRange === mgrs.length ? "✅" : "⚠️"} squad sizes 15-20: ${inRange}/${mgrs.length}` +
    ` (sizes: ${sizeRows.map((r) => r.size).join(",")})`,
);

// 5d. SCORING — app standings must equal an independent recompute
const standings = (await api("/api/standings")).json as Array<{
  id: number;
  teamName: string;
  score: number;
  squadSize: number;
}>;
const appScore = new Map(standings.map((s) => [s.id, s.score]));

let scoreMismatch = 0;
const expectedScores = new Map<number, number>();
for (const m of mgrs) {
  const starters = await prisma.squadEntry.findMany({
    where: { managerId: m.id, playing: true },
    select: { playerId: true, fromAt: true, untilAt: true },
  });
  let exp = 0;
  for (const s of starters) {
    const snaps = await prisma.pointSnapshot.findMany({
      where: {
        playerId: s.playerId,
        kickoffTime: { not: null, gte: s.fromAt, lt: s.untilAt },
      },
      select: { points: true },
    });
    exp += snaps.reduce((a, b) => a + b.points, 0);
  }
  expectedScores.set(m.id, exp);
  if ((appScore.get(m.id) ?? 0) !== exp) {
    scoreMismatch++;
    console.log(`     mismatch ${m.username}: app=${appScore.get(m.id)} expected=${exp}`);
  }
}
if (scoreMismatch === 0)
  console.log(`  ✅ scoring: all ${mgrs.length} manager totals match independent recompute`);
else fail(`${scoreMismatch} manager scores did NOT match`);

// ── 6. RESULTS TABLE ─────────────────────────────────────────────────────────
console.log("\n========== FINAL STANDINGS ==========");
const ranked = [...standings].sort((a, b) => b.score - a.score);
let rank = 1;
for (const s of ranked) {
  console.log(
    `  ${String(rank).padStart(2)}. ${s.teamName.padEnd(14)} squad=${String(s.squadSize).padStart(2)} XI-pts=${s.score}`,
  );
  rank++;
}

console.log("\n========== SUMMARY ==========");
console.log(`  managers: ${mgrs.length} | bids placed: ${totalPlaced} | bids won: ${totalWon}`);
console.log(`  contested auctions checked: ${contests.length}`);
console.log(`  point snapshots: ${snapshots}`);
console.log(failures === 0 ? "  ✅✅ ALL CHECKS PASSED" : `  ❌ ${failures} CHECK GROUP(S) FAILED`);

await prisma.$disconnect();
process.exit(failures === 0 ? 0 : 1);
