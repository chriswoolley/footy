-- CreateTable
CREATE TABLE "Round" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "status" TEXT NOT NULL,
    "startDate" DATETIME NOT NULL,
    "endDate" DATETIME NOT NULL
);

-- CreateTable
CREATE TABLE "Fixture" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "roundId" INTEGER NOT NULL,
    "date" DATETIME NOT NULL,
    "status" TEXT NOT NULL,
    "period" TEXT NOT NULL,
    "minutes" INTEGER NOT NULL DEFAULT 0,
    "extraMinutes" INTEGER NOT NULL DEFAULT 0,
    "venueName" TEXT NOT NULL,
    "venueCity" TEXT NOT NULL,
    "homeSquadId" INTEGER NOT NULL,
    "awaySquadId" INTEGER NOT NULL,
    "homeScore" INTEGER,
    "awayScore" INTEGER,
    "homePenaltyScore" INTEGER,
    "awayPenaltyScore" INTEGER,
    "homeGoalScorers" TEXT,
    "awayGoalScorers" TEXT,
    CONSTRAINT "Fixture_roundId_fkey" FOREIGN KEY ("roundId") REFERENCES "Round" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Fixture_homeSquadId_fkey" FOREIGN KEY ("homeSquadId") REFERENCES "Team" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Fixture_awaySquadId_fkey" FOREIGN KEY ("awaySquadId") REFERENCES "Team" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Player" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "webName" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "knownName" TEXT,
    "teamId" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "nowCost" INTEGER NOT NULL,
    "totalPoints" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'a',
    "news" TEXT NOT NULL DEFAULT '',
    "form" REAL NOT NULL DEFAULT 0,
    "photoCode" INTEGER,
    "percentSelected" REAL,
    "oneToWatch" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Player_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Player" ("firstName", "form", "id", "lastName", "news", "nowCost", "photoCode", "position", "status", "teamId", "totalPoints", "webName") SELECT "firstName", "form", "id", "lastName", "news", "nowCost", "photoCode", "position", "status", "teamId", "totalPoints", "webName" FROM "Player";
DROP TABLE "Player";
ALTER TABLE "new_Player" RENAME TO "Player";
CREATE INDEX "Player_teamId_idx" ON "Player"("teamId");
CREATE INDEX "Player_position_idx" ON "Player"("position");
CREATE TABLE "new_Team" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "shortName" TEXT NOT NULL,
    "group" TEXT,
    "isEliminated" BOOLEAN NOT NULL DEFAULT false
);
INSERT INTO "new_Team" ("id", "name", "shortName") SELECT "id", "name", "shortName" FROM "Team";
DROP TABLE "Team";
ALTER TABLE "new_Team" RENAME TO "Team";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE INDEX "Fixture_roundId_idx" ON "Fixture"("roundId");

-- CreateIndex
CREATE INDEX "Fixture_date_idx" ON "Fixture"("date");

-- CreateIndex
CREATE INDEX "Fixture_homeSquadId_idx" ON "Fixture"("homeSquadId");

-- CreateIndex
CREATE INDEX "Fixture_awaySquadId_idx" ON "Fixture"("awaySquadId");
