import { promises as fs } from "node:fs";
import path from "node:path";
import cron from "node-cron";
import { prisma } from "./prisma.js";

// Daily SQLite backup. Writes a consistent snapshot (VACUUM INTO) to BACKUP_DIR,
// which in Docker is a host-mounted folder so backups outlive the data volume.
const BACKUP_DIR = process.env.BACKUP_DIR ?? "/backups";
const KEEP = Number(process.env.BACKUP_KEEP ?? 14); // how many snapshots to retain
const SCHEDULE = process.env.BACKUP_CRON ?? "0 2 * * *"; // 02:00 daily (container TZ = UTC)

function stamp(d: Date): string {
  const p = (n: number) => String(n).padStart(2, "0");
  return (
    `${d.getUTCFullYear()}${p(d.getUTCMonth() + 1)}${p(d.getUTCDate())}` +
    `-${p(d.getUTCHours())}${p(d.getUTCMinutes())}${p(d.getUTCSeconds())}`
  );
}

/** Take one snapshot now; returns the absolute file path written. */
export async function backupNow(): Promise<string> {
  await fs.mkdir(BACKUP_DIR, { recursive: true });
  const file = path.join(BACKUP_DIR, `dev-${stamp(new Date())}.db`);
  // VACUUM INTO produces a consistent copy even while the DB is in use.
  // The path is server-generated; escape single quotes defensively.
  await prisma.$executeRawUnsafe(`VACUUM INTO '${file.replace(/'/g, "''")}'`);
  await prune();
  return file;
}

/** Keep only the newest KEEP snapshots; delete the rest. */
async function prune(): Promise<void> {
  let files: string[];
  try {
    files = await fs.readdir(BACKUP_DIR);
  } catch {
    return;
  }
  const snapshots = files
    .filter((f) => f.startsWith("dev-") && f.endsWith(".db"))
    .sort(); // timestamp format sorts chronologically as plain strings
  const excess = snapshots.slice(0, Math.max(0, snapshots.length - KEEP));
  for (const f of excess) {
    await fs.rm(path.join(BACKUP_DIR, f), { force: true });
  }
}

export function startBackups(): void {
  if (!cron.validate(SCHEDULE)) {
    console.error(`[backup] invalid BACKUP_CRON "${SCHEDULE}" — backups disabled`);
    return;
  }
  cron.schedule(SCHEDULE, () => {
    backupNow()
      .then((f) => console.log(`[backup] wrote ${path.basename(f)}`))
      .catch((e) => console.error("[backup] failed", e));
  });
  console.log(`[backup] scheduled "${SCHEDULE}" -> ${BACKUP_DIR} (keep ${KEEP})`);
}
