/**
 * Data source: the official FIFA World Cup 2026 Fantasy game's static JSON feeds.
 *
 *   /json/fantasy/squads.json   — 48 teams (id, name, group, abbr, isEliminated)
 *   /json/fantasy/players.json  — every fantasy-eligible player with real prices,
 *                                 positions, ownership %, and live stats
 *   /json/fantasy/rounds.json   — 8 fantasy rounds, each with embedded fixtures
 *                                 (venue, kickoff, status, score, scorers)
 *
 * The endpoints are undocumented but publicly served. They update live during
 * the tournament — pricing is fixed, but `players[].stats`, fixture scores,
 * and `roundsSelected` move.
 */
import { prisma } from "./prisma.js";

const BASE = "https://play.fifa.com/json/fantasy";

// ── Wire types ────────────────────────────────────────────────────────

type FifaSquad = {
  id: number;
  name: string;
  group: string;
  abbr: string;
  isEliminated: boolean;
};

type FifaPlayer = {
  id: number;
  firstName: string;
  lastName: string;
  knownName: string | null;
  squadId: number;
  position: "GK" | "DEF" | "MID" | "FWD";
  price: number;
  status: string;
  matchStatus: string | null;
  percentSelected: number;
  stats: {
    totalPoints: number;
    avgPoints: number;
    form: number;
    lastRoundPoints: number;
    roundPoints: Array<{ round: number; points: number } | number>;
  };
  oneToWatch: boolean;
};

type FifaFixture = {
  id: number;
  period: string;
  minutes: number;
  extraMinutes: number;
  venueName: string;
  venueCity: string;
  date: string;
  status: string;
  homeSquadId: number;
  awaySquadId: number;
  homeScore: number | null;
  awayScore: number | null;
  homePenaltyScore: number | null;
  awayPenaltyScore: number | null;
  homeGoalScorersAssists: unknown;
  awayGoalScorersAssists: unknown;
};

type FifaRound = {
  id: number;
  status: string;
  startDate: string;
  endDate: string;
  tournaments: FifaFixture[];
};

// ── Mappers ───────────────────────────────────────────────────────────

const POS: Record<FifaPlayer["position"], number> = { GK: 1, DEF: 2, MID: 3, FWD: 4 };

// Map FIFA's status enum to the FPL-style letters used by the Market UI.
function mapStatus(s: string): string {
  switch (s) {
    case "playing":
    case "transferred":
      return "a";
    case "injured":
      return "i";
    case "doubtful":
      return "d";
    case "suspended":
      return "s";
    default:
      return "a";
  }
}

// Best display name: FIFA's `knownName` when set, else lastName, else firstName.
function deriveWebName(p: FifaPlayer): string {
  return (p.knownName?.trim() || p.lastName?.trim() || p.firstName?.trim() || "").trim();
}

async function fetchJson<T>(path: string): Promise<T> {
  const res = await fetch(`${BASE}/${path}`);
  if (!res.ok) throw new Error(`fifa fetch ${path} -> ${res.status}`);
  return (await res.json()) as T;
}

// ── Sync routines ─────────────────────────────────────────────────────

export async function syncTeams(): Promise<number> {
  const squads = await fetchJson<FifaSquad[]>("squads.json");
  await prisma.$transaction(async (tx) => {
    for (const s of squads) {
      await tx.team.upsert({
        where: { id: s.id },
        update: {
          name: s.name,
          shortName: s.abbr,
          group: s.group,
          isEliminated: s.isEliminated,
        },
        create: {
          id: s.id,
          name: s.name,
          shortName: s.abbr,
          group: s.group,
          isEliminated: s.isEliminated,
        },
      });
    }
  });
  return squads.length;
}

export async function syncPlayers(): Promise<number> {
  const players = await fetchJson<FifaPlayer[]>("players.json");
  await prisma.$transaction(
    async (tx) => {
      for (const p of players) {
        await tx.player.upsert({
          where: { id: p.id },
          update: {
            webName: deriveWebName(p),
            firstName: p.firstName ?? "",
            lastName: p.lastName ?? "",
            knownName: p.knownName,
            teamId: p.squadId,
            position: POS[p.position],
            nowCost: Math.round(p.price * 10),
            totalPoints: p.stats?.totalPoints ?? 0,
            status: mapStatus(p.status),
            form: p.stats?.form ?? 0,
            percentSelected: p.percentSelected ?? null,
            oneToWatch: !!p.oneToWatch,
          },
          create: {
            id: p.id,
            webName: deriveWebName(p),
            firstName: p.firstName ?? "",
            lastName: p.lastName ?? "",
            knownName: p.knownName,
            teamId: p.squadId,
            position: POS[p.position],
            nowCost: Math.round(p.price * 10),
            totalPoints: p.stats?.totalPoints ?? 0,
            status: mapStatus(p.status),
            news: "",
            form: p.stats?.form ?? 0,
            photoCode: null,
            percentSelected: p.percentSelected ?? null,
            oneToWatch: !!p.oneToWatch,
          },
        });
      }
    },
    { timeout: 60000 },
  );
  await prisma.syncState.upsert({
    where: { key: "bootstrap" },
    update: { value: new Date().toISOString() },
    create: { key: "bootstrap", value: new Date().toISOString() },
  });
  return players.length;
}

/**
 * Capture per-round player scores into PointSnapshot, which the Standings table
 * sums (joined to each manager's playing entries within their ownership window).
 * FIFA exposes `players[].stats.roundPoints` (per-round points); we stamp each
 * snapshot with the round's startDate so a manager only earns a round's points
 * for players they owned when that round began. Empty until the tournament runs.
 * Run AFTER syncPlayers (players must exist) and after syncFixtures (rounds exist).
 */
export async function syncRoundScores(): Promise<{ snapshots: number }> {
  const players = await fetchJson<FifaPlayer[]>("players.json");
  const rounds = await prisma.round.findMany({ select: { id: true, startDate: true } });
  const roundStart = new Map<number, Date>(rounds.map((r) => [r.id, r.startDate]));
  let snapshots = 0;
  await prisma.$transaction(
    async (tx) => {
      for (const p of players) {
        const rp = p.stats?.roundPoints;
        if (!Array.isArray(rp) || rp.length === 0) continue;
        for (let i = 0; i < rp.length; i++) {
          const entry = rp[i];
          // Each entry is either { round, points } or a bare number indexed by round.
          const round = typeof entry === "number" ? i + 1 : entry?.round;
          const points = typeof entry === "number" ? entry : entry?.points;
          if (round == null || points == null) continue;
          await tx.pointSnapshot.upsert({
            where: { playerId_gameweek: { playerId: p.id, gameweek: round } },
            update: {
              points,
              value: Math.round(p.price * 10),
              kickoffTime: roundStart.get(round) ?? null,
            },
            create: {
              playerId: p.id,
              gameweek: round,
              points,
              value: Math.round(p.price * 10),
              kickoffTime: roundStart.get(round) ?? null,
            },
          });
          snapshots++;
        }
      }
    },
    { timeout: 120000 },
  );
  return { snapshots };
}

export async function syncFixtures(): Promise<{ rounds: number; fixtures: number }> {
  const rounds = await fetchJson<FifaRound[]>("rounds.json");
  let fixtureCount = 0;
  await prisma.$transaction(
    async (tx) => {
      for (const r of rounds) {
        await tx.round.upsert({
          where: { id: r.id },
          update: {
            status: r.status,
            startDate: new Date(r.startDate),
            endDate: new Date(r.endDate),
          },
          create: {
            id: r.id,
            status: r.status,
            startDate: new Date(r.startDate),
            endDate: new Date(r.endDate),
          },
        });
        for (const f of r.tournaments) {
          const homeGS = f.homeGoalScorersAssists != null
            ? JSON.stringify(f.homeGoalScorersAssists)
            : null;
          const awayGS = f.awayGoalScorersAssists != null
            ? JSON.stringify(f.awayGoalScorersAssists)
            : null;
          await tx.fixture.upsert({
            where: { id: f.id },
            update: {
              roundId: r.id,
              date: new Date(f.date),
              status: f.status,
              period: f.period,
              minutes: f.minutes ?? 0,
              extraMinutes: f.extraMinutes ?? 0,
              venueName: f.venueName,
              venueCity: f.venueCity,
              homeSquadId: f.homeSquadId,
              awaySquadId: f.awaySquadId,
              homeScore: f.homeScore,
              awayScore: f.awayScore,
              homePenaltyScore: f.homePenaltyScore,
              awayPenaltyScore: f.awayPenaltyScore,
              homeGoalScorers: homeGS,
              awayGoalScorers: awayGS,
            },
            create: {
              id: f.id,
              roundId: r.id,
              date: new Date(f.date),
              status: f.status,
              period: f.period,
              minutes: f.minutes ?? 0,
              extraMinutes: f.extraMinutes ?? 0,
              venueName: f.venueName,
              venueCity: f.venueCity,
              homeSquadId: f.homeSquadId,
              awaySquadId: f.awaySquadId,
              homeScore: f.homeScore,
              awayScore: f.awayScore,
              homePenaltyScore: f.homePenaltyScore,
              awayPenaltyScore: f.awayPenaltyScore,
              homeGoalScorers: homeGS,
              awayGoalScorers: awayGS,
            },
          });
          fixtureCount++;
        }
      }
    },
    { timeout: 60000 },
  );
  await prisma.syncState.upsert({
    where: { key: "fixtures" },
    update: { value: String(fixtureCount) },
    create: { key: "fixtures", value: String(fixtureCount) },
  });
  return { rounds: rounds.length, fixtures: fixtureCount };
}

export async function syncAll(): Promise<{
  teams: number;
  players: number;
  rounds: number;
  fixtures: number;
}> {
  const teams = await syncTeams();
  const players = await syncPlayers();
  const { rounds, fixtures } = await syncFixtures();
  return { teams, players, rounds, fixtures };
}

// ── Wipe + read helpers ───────────────────────────────────────────────

// Wipes everything except settings/audit. Managers are wiped too — this is
// the "complete reset" used before reseeding.
export async function wipeAll(): Promise<void> {
  await prisma.$transaction([
    prisma.pointSnapshot.deleteMany({}),
    prisma.squadEntry.deleteMany({}),
    prisma.bid.deleteMany({}),
    prisma.paperTalk.deleteMany({}),
    prisma.pendingChange.deleteMany({}),
    prisma.player.deleteMany({}),
    prisma.fixture.deleteMany({}),
    prisma.round.deleteMany({}),
    prisma.team.deleteMany({}),
    prisma.manager.deleteMany({}),
    prisma.audit.deleteMany({}),
    prisma.syncState.deleteMany({}),
  ]);
}

// Wipes only player-side data (keeps Manager rows so they can re-bid on a
// freshly-imported player set). Used by /admin/migrate-to-wc.
export async function wipePlayerData(): Promise<void> {
  await prisma.$transaction([
    prisma.pointSnapshot.deleteMany({}),
    prisma.squadEntry.deleteMany({}),
    prisma.bid.deleteMany({}),
    prisma.paperTalk.deleteMany({}),
    prisma.pendingChange.deleteMany({}),
    prisma.player.deleteMany({}),
    prisma.fixture.deleteMany({}),
    prisma.round.deleteMany({}),
    prisma.team.deleteMany({}),
  ]);
}

// Same shape the Fixtures.tsx page expects (a Record<dayString, Fixture[]>).
// Keys are ISO date strings (YYYY-MM-DD), values are sorted by kickoff.
export async function fixturesByDay(): Promise<
  Record<
    string,
    Array<{
      round: string;
      date: string;
      time: string;
      team1: string;
      team2: string;
      group?: string;
      ground?: string;
    }>
  >
> {
  const fixtures = await prisma.fixture.findMany({
    orderBy: { date: "asc" },
    include: {
      homeSquad: true,
      awaySquad: true,
      round: true,
    },
  });
  const out: Record<string, any[]> = {};
  for (const f of fixtures) {
    const iso = f.date.toISOString();
    const day = iso.slice(0, 10);
    const time = iso.slice(11, 16);
    const list = out[day] ?? (out[day] = []);
    list.push({
      round: `Round ${f.roundId}`,
      date: day,
      time,
      team1: f.homeSquad.name,
      team2: f.awaySquad.name,
      group: f.homeSquad.group
        ? `Group ${f.homeSquad.group.toUpperCase()}`
        : undefined,
      ground: `${f.venueName}, ${f.venueCity}`,
    });
  }
  return out;
}
