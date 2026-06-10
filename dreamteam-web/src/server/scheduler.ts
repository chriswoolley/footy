import cron from "node-cron";
import { syncTeams, syncPlayers, syncFixtures, syncRoundScores } from "./fifaFantasy.js";
import { resolvePendingBids } from "./bidding.js";

// All schedules use UK local time so "10:00"/"midnight" mean what players expect.
const TZ = "Europe/London";

// Two independent sync cadences (override via env):
//   SCORES_CRON   — refresh player scores/prices/status        (default hourly)
//   FIXTURES_CRON — pick up new rounds/fixtures (e.g. R4, R5)   (default every 6h)
const SCORES_CRON = process.env.SCORES_CRON ?? "0 * * * *";
const FIXTURES_CRON = process.env.FIXTURES_CRON ?? "0 */6 * * *";

// Bid auction:
//   Normal — runs at midnight (00:00 UK) every day.
//   Boost  — on AUCTION_BOOST_DATE only, also at 10:00 and every 2h to 22:00
//            (midnight is covered by the daily run). After that day → normal.
const AUCTION_BOOST_DATE = process.env.AUCTION_BOOST_DATE ?? "2026-06-11";

// Current date in UK local time as YYYY-MM-DD (Node's ICU handles the tz).
function londonDate(): string {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: TZ,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(new Date());
}

async function runAuction(label: string): Promise<void> {
  try {
    const r = await resolvePendingBids();
    console.log(
      `[auction] ${label}: ${r.won} won, ${r.lost} outbid, ${r.skipped} skipped at ${new Date().toISOString()}`,
    );
  } catch (err) {
    console.error("[auction] failed", err);
  }
}

async function syncScores(): Promise<void> {
  try {
    const players = await syncPlayers();
    const { snapshots } = await syncRoundScores();
    console.log(
      `[scores] refreshed ${players} players, ${snapshots} round-scores at ${new Date().toISOString()}`,
    );
  } catch (err) {
    console.error("[scores] sync failed", err);
  }
}

async function syncRoundsAndFixtures(): Promise<void> {
  try {
    // Teams first so fixtures/players can resolve their squad references.
    const teams = await syncTeams();
    const { rounds, fixtures } = await syncFixtures();
    console.log(
      `[fixtures] synced ${teams} teams, ${rounds} rounds, ${fixtures} fixtures at ${new Date().toISOString()}`,
    );
  } catch (err) {
    console.error("[fixtures] sync failed", err);
  }
}

export function startScheduler(): void {
  cron.schedule(SCORES_CRON, syncScores);
  cron.schedule(FIXTURES_CRON, syncRoundsAndFixtures);

  // Normal auction: midnight UK, every day.
  cron.schedule("0 0 * * *", () => runAuction("midnight"), { timezone: TZ });
  // Boost day only: 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00 UK.
  cron.schedule(
    "0 10,12,14,16,18,20,22 * * *",
    () => {
      if (londonDate() === AUCTION_BOOST_DATE) runAuction("boost");
    },
    { timezone: TZ },
  );

  console.log(
    `[scheduler] scores "${SCORES_CRON}", rounds/fixtures "${FIXTURES_CRON}"; ` +
      `auction midnight daily, boost 2-hourly on ${AUCTION_BOOST_DATE} (${TZ})`,
  );
  // Initial populate on boot: teams + fixtures first, then player scores.
  syncRoundsAndFixtures().then(syncScores);
}
