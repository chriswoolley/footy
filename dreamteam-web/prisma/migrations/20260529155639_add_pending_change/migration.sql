-- CreateTable
CREATE TABLE "PendingChange" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "managerId" INTEGER NOT NULL,
    "kind" TEXT NOT NULL,
    "playerId" INTEGER NOT NULL,
    "toSlot" INTEGER,
    "effectiveAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PendingChange_managerId_fkey" FOREIGN KEY ("managerId") REFERENCES "Manager" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateIndex
CREATE INDEX "PendingChange_managerId_idx" ON "PendingChange"("managerId");

-- CreateIndex
CREATE INDEX "PendingChange_effectiveAt_idx" ON "PendingChange"("effectiveAt");
