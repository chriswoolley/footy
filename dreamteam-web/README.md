# DreamTeam Web

Web reimplementation of the Delphi DreamTeam fantasy football manager. Originally targeted the Premier League via the Fantasy Premier League API; now sourcing data for the **2026 FIFA World Cup** from openfootball + a curated player roster.

## Quick start

```bash
npm install
npx prisma migrate dev --name init
npm run dev
```

Open http://localhost:5173 — register a manager, then pick a squad of national-team players.

## How it works

- **Backend** (Express, port 3000) reads fixtures + venues from [openfootball/worldcup.json](https://github.com/openfootball/worldcup.json) (public domain, no key) and combines them with a hand-curated roster in `src/server/wc2026Players.ts`.
- **Scheduler** refreshes nightly (3am). Live match polling kicks in once the tournament starts on 11 June 2026.
- **Frontend** (Vite + React, port 5173) proxies `/api/*` to the backend.

## Features

| Original Delphi | Page |
|---|---|
| Login / Register | `/login` |
| Squad pitch with 1-4-4-2 / 1-4-3-3 | `/squad` |
| Transfer market with bids | `/market` |
| Overall standings | `/standings` |
| Points leaderboard | `/points` |
| Paper Talk events | `/paper-talk` |
| Charts (team & player over time) | `/graphs` |
| — (new) World Cup fixtures | `/fixtures` |
| — (new) Admin console | `/admin` |

## Data sources

- **Fixtures / groups / venues:** [openfootball/worldcup.json](https://github.com/openfootball/worldcup.json) — free, no key.
- **Players:** Hand-curated marquee names for 18 top nations + placeholder rosters for the other 30, in `src/server/wc2026Players.ts`. Replace any team's array with real data once a real API key is in play.
- **Live match stats (post 11 Jun 2026):** plug in [BALLDONTLIE FIFA](https://fifa.balldontlie.io/), [API-Football](https://www.api-football.com/), or [Sportmonks](https://www.sportmonks.com/football-api/world-cup-api/) via a future `wc2026Live.ts` module.

## Reverting to Premier League data

`src/server/fpl.ts` is still in the tree. Call `POST /api/admin/sync-fpl` to re-load Premier League data, but you'll need to wipe World Cup data first (`POST /api/admin/migrate-to-wc` is the reverse direction; a `migrate-to-fpl` equivalent is one trivial route copy away).
