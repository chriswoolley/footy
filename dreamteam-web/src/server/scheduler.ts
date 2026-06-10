import cron from "node-cron";
import { syncTeams, syncPlayers, syncFixtures, syncRoundScores } from "./fifaFantasy.js";

// Two independent cadences (container clock is UTC; override via env):
//   SCORES_CRON   — refresh player scores/prices/status        (default hourly)
//   FIXTURES_CRON — pick up new rounds/fixtures (e.g. R4, R5)   (default every 6h)
const SCORES_CRON = process.env.SCORES_CRON ?? "0 * * * *";
const FIXTURES_CRON = process.env.FIXTURES_CRON ?? "0 */6 * * *";

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
  console.log(`[scheduler] scores "${SCORES_CRON}", rounds/fixtures "${FIXTURES_CRON}"`);
  // Initial populate on boot: teams + fixtures first, then player scores.
  syncRoundsAndFixtures().then(syncScores);
}
