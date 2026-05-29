/**
 * World Cup 2026 data source.
 *
 * Pulls fixtures + venues from openfootball/worldcup.json (free, no key)
 * and combines them with a hand-curated local roster (see wc2026Players.ts).
 *
 * To swap in a real API later: replace `fetchRoster` with a call to
 * BALLDONTLIE / API-Football / Sportmonks. The function shape (returning
 * an array of { name, position, value, country }) is provider-agnostic.
 */
import { prisma } from "./prisma.js";
import {
  MARQUEE_SQUADS,
  fillerSquadFor,
  type WcPlayer,
} from "./wc2026Players.js";

const FIXTURES_URL =
  "https://raw.githubusercontent.com/openfootball/worldcup.json/master/2026/worldcup.json";

// ── The 48 qualifying teams, grouped A..L (from openfootball cup.txt) ──
// IDs are stable so re-running the sync doesn't churn FK relationships.
export const WC_TEAMS: Array<{ id: number; code: string; name: string; group: string }> = [
  { id: 1, code: "MEX", name: "Mexico", group: "A" },
  { id: 2, code: "RSA", name: "South Africa", group: "A" },
  { id: 3, code: "KOR", name: "South Korea", group: "A" },
  { id: 4, code: "CZE", name: "Czech Republic", group: "A" },
  { id: 5, code: "CAN", name: "Canada", group: "B" },
  { id: 6, code: "BIH", name: "Bosnia & Herzegovina", group: "B" },
  { id: 7, code: "QAT", name: "Qatar", group: "B" },
  { id: 8, code: "SUI", name: "Switzerland", group: "B" },
  { id: 9, code: "BRA", name: "Brazil", group: "C" },
  { id: 10, code: "MAR", name: "Morocco", group: "C" },
  { id: 11, code: "HAI", name: "Haiti", group: "C" },
  { id: 12, code: "SCO", name: "Scotland", group: "C" },
  { id: 13, code: "USA", name: "USA", group: "D" },
  { id: 14, code: "PAR", name: "Paraguay", group: "D" },
  { id: 15, code: "AUS", name: "Australia", group: "D" },
  { id: 16, code: "TUR", name: "Türkiye", group: "D" },
  { id: 17, code: "GER", name: "Germany", group: "E" },
  { id: 18, code: "CUW", name: "Curaçao", group: "E" },
  { id: 19, code: "CIV", name: "Côte d'Ivoire", group: "E" },
  { id: 20, code: "ECU", name: "Ecuador", group: "E" },
  { id: 21, code: "NED", name: "Netherlands", group: "F" },
  { id: 22, code: "JPN", name: "Japan", group: "F" },
  { id: 23, code: "SWE", name: "Sweden", group: "F" },
  { id: 24, code: "TUN", name: "Tunisia", group: "F" },
  { id: 25, code: "BEL", name: "Belgium", group: "G" },
  { id: 26, code: "EGY", name: "Egypt", group: "G" },
  { id: 27, code: "IRN", name: "IR Iran", group: "G" },
  { id: 28, code: "NZL", name: "New Zealand", group: "G" },
  { id: 29, code: "ESP", name: "Spain", group: "H" },
  { id: 30, code: "CPV", name: "Cabo Verde", group: "H" },
  { id: 31, code: "KSA", name: "Saudi Arabia", group: "H" },
  { id: 32, code: "URU", name: "Uruguay", group: "H" },
  { id: 33, code: "FRA", name: "France", group: "I" },
  { id: 34, code: "SEN", name: "Senegal", group: "I" },
  { id: 35, code: "IRQ", name: "Iraq", group: "I" },
  { id: 36, code: "NOR", name: "Norway", group: "I" },
  { id: 37, code: "ARG", name: "Argentina", group: "J" },
  { id: 38, code: "ALG", name: "Algeria", group: "J" },
  { id: 39, code: "AUT", name: "Austria", group: "J" },
  { id: 40, code: "JOR", name: "Jordan", group: "J" },
  { id: 41, code: "POR", name: "Portugal", group: "K" },
  { id: 42, code: "COD", name: "DR Congo", group: "K" },
  { id: 43, code: "UZB", name: "Uzbekistan", group: "K" },
  { id: 44, code: "COL", name: "Colombia", group: "K" },
  { id: 45, code: "ENG", name: "England", group: "L" },
  { id: 46, code: "CRO", name: "Croatia", group: "L" },
  { id: 47, code: "GHA", name: "Ghana", group: "L" },
  { id: 48, code: "PAN", name: "Panama", group: "L" },
];

const POSITION_TO_INT: Record<WcPlayer["position"], number> = {
  GK: 1,
  DEF: 2,
  MID: 3,
  FWD: 4,
};

type OpenfootballFixture = {
  round: string;
  date: string;
  time?: string;
  team1: string;
  team2: string;
  group?: string;
  ground?: string;
};

export async function fetchFixtures(): Promise<OpenfootballFixture[]> {
  const res = await fetch(FIXTURES_URL);
  if (!res.ok) throw new Error(`openfootball ${res.status}`);
  const data = (await res.json()) as { matches: OpenfootballFixture[] };
  return data.matches ?? [];
}

export async function syncTeamsAndPlayers(): Promise<{
  teams: number;
  players: number;
}> {
  let playerCount = 0;
  await prisma.$transaction(async (tx) => {
    // Upsert all 48 teams
    for (const t of WC_TEAMS) {
      await tx.team.upsert({
        where: { id: t.id },
        update: { name: t.name, shortName: t.code },
        create: { id: t.id, name: t.name, shortName: t.code },
      });
    }

    // Generate a stable player ID per (teamCode, slotIndex)
    let nextId = 1;
    for (const team of WC_TEAMS) {
      const marquee = MARQUEE_SQUADS[team.code];
      const roster: WcPlayer[] = marquee ?? fillerSquadFor(team.code);
      for (const p of roster) {
        const id = nextId++;
        await tx.player.upsert({
          where: { id },
          update: {
            webName: p.name,
            firstName: p.name,
            lastName: "",
            teamId: team.id,
            position: POSITION_TO_INT[p.position],
            nowCost: Math.round(p.value * 10),
            status: "a",
            news: "",
            photoCode: null,
          },
          create: {
            id,
            webName: p.name,
            firstName: p.name,
            lastName: "",
            teamId: team.id,
            position: POSITION_TO_INT[p.position],
            nowCost: Math.round(p.value * 10),
            totalPoints: 0,
            status: "a",
            news: "",
            form: 0,
            photoCode: null,
          },
        });
        playerCount++;
      }
    }

    await tx.syncState.upsert({
      where: { key: "bootstrap" },
      update: { value: new Date().toISOString() },
      create: { key: "bootstrap", value: new Date().toISOString() },
    });
  });
  return { teams: WC_TEAMS.length, players: playerCount };
}

export async function syncFixtures(): Promise<number> {
  // We don't have a Fixture model in the schema yet; for now we just stash
  // the count so the admin status can show it. Fixtures are surfaced as
  // they come live via the API in a later iteration.
  const fixtures = await fetchFixtures();
  await prisma.syncState.upsert({
    where: { key: "fixtures" },
    update: { value: String(fixtures.length) },
    create: { key: "fixtures", value: String(fixtures.length) },
  });
  return fixtures.length;
}

export async function fixturesByDay(): Promise<
  Record<string, OpenfootballFixture[]>
> {
  const fixtures = await fetchFixtures();
  const byDay: Record<string, OpenfootballFixture[]> = {};
  for (const m of fixtures) {
    byDay[m.date] = byDay[m.date] ?? [];
    byDay[m.date].push(m);
  }
  return byDay;
}

export async function wipePremierLeagueData(): Promise<void> {
  await prisma.$transaction([
    prisma.pointSnapshot.deleteMany({}),
    prisma.squadEntry.deleteMany({}),
    prisma.bid.deleteMany({}),
    prisma.paperTalk.deleteMany({}),
    prisma.player.deleteMany({}),
    prisma.team.deleteMany({}),
  ]);
}
