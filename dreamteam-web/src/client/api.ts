async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(path, {
    credentials: "include",
    headers: { "content-type": "application/json", ...(init?.headers ?? {}) },
    ...init,
  });
  if (!res.ok) {
    let msg = res.statusText;
    try {
      const body = await res.json();
      msg = body.error ?? msg;
    } catch {
      // ignore
    }
    throw new Error(msg);
  }
  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

export const api = {
  get: <T>(p: string) => request<T>(p),
  post: <T>(p: string, body?: unknown) =>
    request<T>(p, { method: "POST", body: body ? JSON.stringify(body) : undefined }),
  del: <T>(p: string) => request<T>(p, { method: "DELETE" }),
};

export type Me = {
  id: number;
  username: string;
  teamName: string;
  email: string | null;
  formation: "442" | "433";
  isAdmin: boolean;
};

export type Player = {
  id: number;
  name: string;
  firstName: string;
  lastName: string;
  team: string;
  teamShort: string;
  teamId: number;
  position: 1 | 2 | 3 | 4;
  price: number;
  points: number;
  form: number;
  status: string;
  news: string;
  photoUrl: string | null;
  ownedBy: { managerId: number; teamName: string } | null;
};

export type SquadEntryDTO = {
  id: number;
  playerId: number;
  name: string;
  team: string;
  teamShort: string;
  position: 1 | 2 | 3 | 4;
  price: number;
  points: number;
  bid: number;
  playing: boolean;
  formationSlot: number | null;
  photoUrl: string | null;
};

export type Squad = {
  budget: number;
  spent: number;
  balance: number;
  bidMode: "immediate" | "deferred";
  entries: SquadEntryDTO[];
};

export type StandingRow = {
  rank: number;
  id: number;
  username: string;
  teamName: string;
  squadSize: number;
  score: number;
};

export type PaperTalkRow = {
  id: number;
  when: string;
  manager: string | null;
  team: string | null;
  player: string | null;
  reason: string;
  bid: number | null;
};

export type GraphPoint = { gameweek: number; points: number; value?: number };
