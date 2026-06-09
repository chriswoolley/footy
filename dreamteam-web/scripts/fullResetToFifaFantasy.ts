/**
 * One-shot reset:
 *   1. Wipe every table
 *   2. Pull teams, players, rounds, and fixtures from FIFA's official fantasy feeds
 *   3. Create the CWoolley manager
 */
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import { randomBytes } from "node:crypto";
import { syncAll, wipeAll } from "../src/server/fifaFantasy.js";

const p = new PrismaClient();

console.log("[reset] wiping every table...");
await wipeAll();

console.log("[reset] syncing FIFA fantasy data (squads, players, rounds, fixtures)...");
const { teams, players, rounds, fixtures } = await syncAll();
console.log(`[reset]   ${teams} teams, ${players} players, ${rounds} rounds, ${fixtures} fixtures`);

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
