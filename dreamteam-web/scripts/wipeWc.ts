import { PrismaClient } from "@prisma/client";

const p = new PrismaClient();
const wcCodes = [
  "MEX","RSA","KOR","CZE","CAN","BIH","QAT","SUI","BRA","MAR","HAI","SCO",
  "USA","PAR","AUS","TUR","GER","CUW","CIV","ECU","NED","JPN","SWE","TUN",
  "BEL","EGY","IRN","NZL","ESP","CPV","KSA","URU","FRA","SEN","IRQ","NOR",
  "ARG","ALG","AUT","JOR","POR","COD","UZB","COL","ENG","CRO","GHA","PAN",
];

const leftover = await p.team.findMany({
  where: { shortName: { in: wcCodes } },
  include: { _count: { select: { players: true } } },
});
const ids = leftover.map((t) => t.id);
const withPlayers = leftover.filter((t) => t._count.players > 0);
if (withPlayers.length > 0) {
  console.error("aborting: WC teams still have player rows", withPlayers);
  process.exit(1);
}

const deletedTeams = await p.team.deleteMany({ where: { id: { in: ids } } });
const deletedFixturesSync = await p.syncState.deleteMany({
  where: { key: "fixtures" },
});

console.log({
  deletedTeams: deletedTeams.count,
  deletedFixturesSync: deletedFixturesSync.count,
  remainingTeams: await p.team.count(),
});

await p.$disconnect();
