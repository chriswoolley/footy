import { PrismaClient } from "@prisma/client";
import { syncBootstrap, syncGameweek, syncPlayerHistory } from "../src/server/fpl.js";

const p = new PrismaClient();

console.log("[reset] wiping player-related tables...");
await p.$transaction([
  p.pointSnapshot.deleteMany({}),
  p.squadEntry.deleteMany({}),
  p.bid.deleteMany({}),
  p.paperTalk.deleteMany({}),
  p.player.deleteMany({}),
  p.team.deleteMany({}),
  p.syncState.deleteMany({}),
]);

console.log("[reset] running FPL bootstrap...");
const data = await syncBootstrap();
console.log(`[reset] bootstrap: ${data.teams.length} teams, ${data.elements.length} players`);

console.log("[reset] syncing all finished + current gameweeks (live data)...");
const liveGws = data.events
  .filter((e) => e.finished || e.is_current)
  .map((e) => e.id);
for (const gw of liveGws) {
  await syncGameweek(gw);
  console.log(`[reset]   GW${gw} live snapshot done`);
}

console.log(`[reset] backfilling per-player history for ${data.elements.length} players (concurrency 4)...`);
let done = 0;
const queue = [...data.elements];
const workers = Array.from({ length: 4 }, async () => {
  while (queue.length > 0) {
    const el = queue.shift();
    if (!el) break;
    try {
      await syncPlayerHistory(el.id);
    } catch (err: any) {
      console.warn(`[reset]   player ${el.id} (${el.web_name}) history failed: ${err.message}`);
    }
    done++;
    if (done % 100 === 0) console.log(`[reset]   ...${done}/${data.elements.length} histories`);
  }
});
await Promise.all(workers);

const counts = {
  teams: await p.team.count(),
  players: await p.player.count(),
  snapshots: await p.pointSnapshot.count(),
};
console.log("[reset] done", counts);

await p.$disconnect();
