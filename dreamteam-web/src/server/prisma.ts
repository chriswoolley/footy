import { PrismaClient } from "@prisma/client";

// Fall back to the bundled SQLite file if the host doesn't inject DATABASE_URL
// (e.g. a Render service created without the render.yaml blueprint). Must be set
// before PrismaClient is constructed. Resolved relative to prisma/schema.prisma.
process.env.DATABASE_URL ??= "file:./dev.db";

export const prisma = new PrismaClient();
