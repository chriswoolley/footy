import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import { randomBytes } from "node:crypto";
import { syncTeamsAndPlayers, syncFixtures } from "../src/server/wc2026.js";

const p = new PrismaClient();

console.log("[reset] wiping ALL tables...");
await p.$transaction([
  p.pointSnapshot.deleteMany({}),
  p.squadEntry.deleteMany({}),
  p.bid.deleteMany({}),
  p.paperTalk.deleteMany({}),
  p.pendingChange.deleteMany({}),
  p.player.deleteMany({}),
  p.team.deleteMany({}),
  p.manager.deleteMany({}),
  p.audit.deleteMany({}),
  p.syncState.deleteMany({}),
]);

console.log("[reset] syncing World Cup 2026 teams + players...");
const { teams, players } = await syncTeamsAndPlayers();
console.log(`[reset]   ${teams} teams, ${players} players`);

console.log("[reset] syncing fixtures from openfootball...");
const fixtures = await syncFixtures();
console.log(`[reset]   ${fixtures} fixtures`);

console.log("[reset] creating manager CWoolley...");
const password = randomBytes(9).toString("base64url");
const manager = await p.manager.create({
  data: {
    username: "CWoolley",
    passwordHash: bcrypt.hashSync(password, 10),
    teamName: "Woolley's",
    email: "cwoolley@lablogic.com",
    formation: "442",
  },
});

console.log("[reset] done.");
console.log("");
console.log("─────────────────────────────────────");
console.log(`  manager id : ${manager.id}`);
console.log(`  username   : ${manager.username}`);
console.log(`  team       : ${manager.teamName}`);
console.log(`  password   : ${password}`);
console.log("─────────────────────────────────────");
console.log("  ^ change after first login");

await p.$disconnect();
