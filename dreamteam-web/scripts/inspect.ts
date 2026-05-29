import { PrismaClient } from "@prisma/client";

const p = new PrismaClient();
const wcCodes = [
  "MEX","RSA","KOR","CZE","CAN","BIH","QAT","SUI","BRA","MAR","HAI","SCO",
  "USA","PAR","AUS","TUR","GER","CUW","CIV","ECU","NED","JPN","SWE","TUN",
  "BEL","EGY","IRN","NZL","ESP","CPV","KSA","URU","FRA","SEN","IRQ","NOR",
  "ARG","ALG","AUT","JOR","POR","COD","UZB","COL","ENG","CRO","GHA","PAN",
];

const teams = await p.team.count();
const wcTeams = await p.team.count({ where: { shortName: { in: wcCodes } } });
const players = await p.player.count();
const playersInWc = await p.player.count({
  where: { team: { shortName: { in: wcCodes } } },
});
const playersNoLast = await p.player.count({ where: { lastName: "" } });
const sampleWcTeams = await p.team.findMany({
  where: { shortName: { in: wcCodes } },
  select: { id: true, shortName: true, name: true },
  take: 10,
});
const sampleFplTeams = await p.team.findMany({
  where: { shortName: { notIn: wcCodes } },
  select: { id: true, shortName: true, name: true },
  take: 10,
});
console.log({ teams, wcTeams, players, playersInWc, playersNoLast });
console.log("sampleWcTeams", sampleWcTeams);
console.log("sampleFplTeams", sampleFplTeams);

const squadOnWc = await p.squadEntry.count({
  where: { player: { team: { shortName: { in: wcCodes } } } },
});
const bidsOnWc = await p.bid.count({
  where: { player: { team: { shortName: { in: wcCodes } } } },
});
const snapsOnWc = await p.pointSnapshot.count({
  where: { player: { team: { shortName: { in: wcCodes } } } },
});
console.log({ squadOnWc, bidsOnWc, snapsOnWc });

await p.$disconnect();
