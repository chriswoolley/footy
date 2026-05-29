-- CreateTable
CREATE TABLE "Manager" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "teamName" TEXT NOT NULL,
    "email" TEXT,
    "formation" TEXT NOT NULL DEFAULT '442',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Team" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "shortName" TEXT NOT NULL
);

-- CreateTable
CREATE TABLE "Player" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "webName" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "teamId" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "nowCost" INTEGER NOT NULL,
    "totalPoints" INTEGER NOT NULL DEFAULT 0,
    "status" TEXT NOT NULL DEFAULT 'a',
    "news" TEXT NOT NULL DEFAULT '',
    "form" REAL NOT NULL DEFAULT 0,
    CONSTRAINT "Player_teamId_fkey" FOREIGN KEY ("teamId") REFERENCES "Team" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "PointSnapshot" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "playerId" INTEGER NOT NULL,
    "gameweek" INTEGER NOT NULL,
    "points" INTEGER NOT NULL,
    "value" INTEGER NOT NULL,
    "kickoffTime" DATETIME,
    "recordedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PointSnapshot_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "SquadEntry" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "managerId" INTEGER NOT NULL,
    "playerId" INTEGER NOT NULL,
    "fromAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "untilAt" DATETIME NOT NULL,
    "bid" REAL NOT NULL,
    "playing" BOOLEAN NOT NULL DEFAULT false,
    "formationSlot" INTEGER,
    CONSTRAINT "SquadEntry_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "Manager" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "SquadEntry_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Bid" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "managerId" INTEGER NOT NULL,
    "playerId" INTEGER NOT NULL,
    "amount" REAL NOT NULL,
    "placedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolved" BOOLEAN NOT NULL DEFAULT false,
    "won" BOOLEAN NOT NULL DEFAULT false,
    CONSTRAINT "Bid_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "Manager" ("id") ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT "Bid_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "PaperTalk" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "when" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "managerId" INTEGER,
    "teamName" TEXT,
    "playerName" TEXT,
    "reason" TEXT NOT NULL,
    "bid" REAL,
    CONSTRAINT "PaperTalk_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "Manager" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Audit" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "who" TEXT NOT NULL,
    "what" TEXT NOT NULL,
    "when" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "SyncState" (
    "key" TEXT NOT NULL PRIMARY KEY,
    "value" TEXT NOT NULL,
    "when" DATETIME NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "Manager_username_key" ON "Manager"("username");

-- CreateIndex
CREATE INDEX "Player_teamId_idx" ON "Player"("teamId");

-- CreateIndex
CREATE INDEX "Player_position_idx" ON "Player"("position");

-- CreateIndex
CREATE INDEX "PointSnapshot_gameweek_idx" ON "PointSnapshot"("gameweek");

-- CreateIndex
CREATE UNIQUE INDEX "PointSnapshot_playerId_gameweek_key" ON "PointSnapshot"("playerId", "gameweek");

-- CreateIndex
CREATE INDEX "SquadEntry_managerId_idx" ON "SquadEntry"("managerId");

-- CreateIndex
CREATE INDEX "SquadEntry_playerId_idx" ON "SquadEntry"("playerId");
