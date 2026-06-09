import cron from "node-cron";
import { syncAll } from "./fifaFantasy.js";

async function refresh() {
  try {
    const { teams, players, rounds, fixtures } = await syncAll();
    console.log(
      `[fifa] synced ${teams} teams, ${players} players, ${rounds} rounds, ${fixtures} fixtures at ${new Date().toISOString()}`,
    );
  } catch (err) {
    console.error("[fifa] sync failed", err);
  }
}

export function startScheduler() {
  cron.schedule("*/10 * * * *", refresh);
  refresh();
}
