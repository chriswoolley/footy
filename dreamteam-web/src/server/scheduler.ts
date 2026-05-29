import cron from "node-cron";
import { syncBootstrap, syncGameweek } from "./fpl.js";

async function refresh() {
  try {
    const data = await syncBootstrap();
    const current =
      data.events.find((e) => e.is_current) ?? data.events.find((e) => e.is_next);
    let liveGw: number | null = null;
    if (current) {
      await syncGameweek(current.id);
      liveGw = current.id;
    }
    console.log(
      `[fpl] synced ${data.teams.length} teams, ${data.elements.length} players, GW${liveGw ?? "?"} at ${new Date().toISOString()}`,
    );
  } catch (err) {
    console.error("[fpl] sync failed", err);
  }
}

export function startScheduler() {
  cron.schedule("*/10 * * * *", refresh);
  refresh();
}
