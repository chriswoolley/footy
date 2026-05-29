import { prisma } from "./prisma.js";

const BASE = "https://fantasy.premierleague.com/api/";

export type FplBootstrap = {
  events: Array<{
    id: number;
    name: string;
    deadline_time: string;
    finished: boolean;
    is_current: boolean;
    is_next: boolean;
    average_entry_score: number;
    highest_score: number | null;
    top_element: number | null;
  }>;
  teams: Array<{ id: number; name: string; short_name: string }>;
  elements: Array<{
    id: number;
    code: number;
    first_name: string;
    second_name: string;
    web_name: string;
    team: number;
    element_type: number;
    now_cost: number;
    total_points: number;
    status: string;
    news: string;
    form: string;
  }>;
};

export type FplLive = {
  elements: Array<{
    id: number;
    stats: {
      minutes: number;
      goals_scored: number;
      assists: number;
      clean_sheets: number;
      goals_conceded: number;
      bonus: number;
      bps: number;
      total_points: number;
    };
  }>;
};

export type FplPlayerSummary = {
  history: Array<{
    element: number;
    round: number;
    total_points: number;
    value: number;
    kickoff_time: string;
  }>;
  history_past: Array<{
    season_name: string;
    total_points: number;
    end_cost: number;
  }>;
};

async function fetchJson<T>(path: string): Promise<T> {
  const res = await fetch(BASE + path, {
    headers: { "user-agent": "DreamTeamWeb/0.1 (+local)" },
  });
  if (!res.ok) throw new Error(`FPL ${path} → ${res.status}`);
  return (await res.json()) as T;
}

export async function fetchBootstrap(): Promise<FplBootstrap> {
  return fetchJson<FplBootstrap>("bootstrap-static/");
}

export async function fetchLive(gw: number): Promise<FplLive> {
  return fetchJson<FplLive>(`event/${gw}/live/`);
}

export async function fetchPlayer(id: number): Promise<FplPlayerSummary> {
  return fetchJson<FplPlayerSummary>(`element-summary/${id}/`);
}

export async function syncBootstrap(): Promise<FplBootstrap> {
  const data = await fetchBootstrap();

  await prisma.$transaction(async (tx) => {
    for (const t of data.teams) {
      await tx.team.upsert({
        where: { id: t.id },
        update: { name: t.name, shortName: t.short_name },
        create: { id: t.id, name: t.name, shortName: t.short_name },
      });
    }
    for (const e of data.elements) {
      await tx.player.upsert({
        where: { id: e.id },
        update: {
          webName: e.web_name,
          firstName: e.first_name,
          lastName: e.second_name,
          teamId: e.team,
          position: e.element_type,
          nowCost: e.now_cost,
          totalPoints: e.total_points,
          status: e.status,
          news: e.news ?? "",
          form: Number(e.form) || 0,
          photoCode: e.code,
        },
        create: {
          id: e.id,
          webName: e.web_name,
          firstName: e.first_name,
          lastName: e.second_name,
          teamId: e.team,
          position: e.element_type,
          nowCost: e.now_cost,
          totalPoints: e.total_points,
          status: e.status,
          news: e.news ?? "",
          form: Number(e.form) || 0,
          photoCode: e.code,
        },
      });
    }
    await tx.syncState.upsert({
      where: { key: "bootstrap" },
      update: { value: new Date().toISOString() },
      create: { key: "bootstrap", value: new Date().toISOString() },
    });
  });

  return data;
}

export async function syncGameweek(gw: number): Promise<void> {
  const data = await fetchLive(gw);
  for (const e of data.elements) {
    const player = await prisma.player.findUnique({ where: { id: e.id } });
    if (!player) continue;
    await prisma.pointSnapshot.upsert({
      where: { playerId_gameweek: { playerId: e.id, gameweek: gw } },
      update: {
        points: e.stats.total_points,
        value: player.nowCost,
      },
      create: {
        playerId: e.id,
        gameweek: gw,
        points: e.stats.total_points,
        value: player.nowCost,
      },
    });
  }
  await prisma.syncState.upsert({
    where: { key: `live:${gw}` },
    update: { value: new Date().toISOString() },
    create: { key: `live:${gw}`, value: new Date().toISOString() },
  });
}

// PL fixtures endpoint shape (only the fields the UI needs).
export type FplFixture = {
  id: number;
  event: number | null; // gameweek
  finished: boolean;
  kickoff_time: string | null;
  team_a: number;
  team_h: number;
  team_a_score: number | null;
  team_h_score: number | null;
};

export async function fetchPlFixtures(): Promise<FplFixture[]> {
  return fetchJson<FplFixture[]>("fixtures/");
}

// Returns the same { date, time, team1, team2, round, group, ground } shape
// the WC fixtures endpoint produces, grouped by ISO date (YYYY-MM-DD), so the
// existing Fixtures page can render PL fixtures with no client changes.
export async function plFixturesByDay(): Promise<
  Record<
    string,
    Array<{
      round: string;
      date: string;
      time?: string;
      team1: string;
      team2: string;
      group?: string;
      ground?: string;
    }>
  >
> {
  const [fixtures, teams] = await Promise.all([
    fetchPlFixtures(),
    prisma.team.findMany({ select: { id: true, name: true } }),
  ]);
  const teamName = new Map(teams.map((t) => [t.id, t.name]));

  const out: Record<
    string,
    Array<{
      round: string;
      date: string;
      time?: string;
      team1: string;
      team2: string;
      group?: string;
      ground?: string;
    }>
  > = {};
  for (const f of fixtures) {
    if (!f.kickoff_time) continue;
    const dt = new Date(f.kickoff_time);
    const date = dt.toISOString().slice(0, 10);
    const time = dt.toISOString().slice(11, 16);
    const home = teamName.get(f.team_h) ?? `Team ${f.team_h}`;
    const away = teamName.get(f.team_a) ?? `Team ${f.team_a}`;
    const score =
      f.finished && f.team_h_score != null && f.team_a_score != null
        ? ` ${f.team_h_score}–${f.team_a_score}`
        : "";
    (out[date] ??= []).push({
      round: f.event != null ? `GW${f.event}` : "—",
      date,
      time,
      team1: home,
      team2: away + score,
      group: f.event != null ? `GW${f.event}` : undefined,
    });
  }
  return out;
}

export async function syncPlayerHistory(playerId: number): Promise<void> {
  const data = await fetchPlayer(playerId);
  for (const h of data.history) {
    await prisma.pointSnapshot.upsert({
      where: { playerId_gameweek: { playerId: h.element, gameweek: h.round } },
      update: {
        points: h.total_points,
        value: h.value,
        kickoffTime: new Date(h.kickoff_time),
      },
      create: {
        playerId: h.element,
        gameweek: h.round,
        points: h.total_points,
        value: h.value,
        kickoffTime: new Date(h.kickoff_time),
      },
    });
  }
}
