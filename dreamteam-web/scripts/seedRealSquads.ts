/**
 * Replaces the hand-curated stop-gap rosters with real squad data parsed from
 * the Wikipedia "2026 FIFA World Cup squads" page (wikitext via MediaWiki API).
 *
 * Keeps Team and Manager rows intact; replaces all Player rows. Run after the
 * initial WC reset so the 48 teams already exist with stable IDs.
 */
import { PrismaClient } from "@prisma/client";
import { WC_TEAMS } from "../src/server/wc2026.js";

const WIKI_API =
  "https://en.wikipedia.org/w/api.php?action=parse&page=2026_FIFA_World_Cup_squads&format=json&prop=wikitext&formatversion=2";

const p = new PrismaClient();

// Wikipedia section heading -> our FIFA 3-letter code.
// Most names match by .name lookup; this table handles the rest.
const WIKI_TO_CODE: Record<string, string> = {
  "Bosnia and Herzegovina": "BIH",
  Turkey: "TUR",
  "United States": "USA",
  "Ivory Coast": "CIV",
  Iran: "IRN",
  "Cape Verde": "CPV",
};

const POS_TO_INT: Record<string, number> = { GK: 1, DF: 2, MF: 3, FW: 4 };

type ParsedPlayer = {
  no: number;
  pos: "GK" | "DF" | "MF" | "FW";
  firstName: string;
  lastName: string;
  webName: string;
  caps: number;
  goals: number;
};

// Pull the body of a {{nat fs g player|...}} template starting at `start`.
// Brace-balanced so the inner {{birth date and age2|...}} doesn't terminate us.
function readTemplate(wt: string, start: number): { body: string; end: number } | null {
  if (wt.slice(start, start + 2) !== "{{") return null;
  let depth = 0;
  let i = start;
  while (i < wt.length - 1) {
    if (wt[i] === "{" && wt[i + 1] === "{") {
      depth++;
      i += 2;
    } else if (wt[i] === "}" && wt[i + 1] === "}") {
      depth--;
      i += 2;
      if (depth === 0) return { body: wt.slice(start + 2, i - 2), end: i };
    } else {
      i++;
    }
  }
  return null;
}

// Parse |key=value pairs out of a template body, respecting nested {{ }}.
function parseParams(body: string): Record<string, string> {
  const params: Record<string, string> = {};
  let depth = 0;
  let cur = "";
  const parts: string[] = [];
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (c === "{" && body[i + 1] === "{") {
      depth++;
      cur += c;
    } else if (c === "}" && body[i + 1] === "}") {
      depth--;
      cur += c;
    } else if (c === "|" && depth === 0) {
      parts.push(cur);
      cur = "";
    } else {
      cur += c;
    }
  }
  parts.push(cur);
  // first part is the template name ("nat fs g player"); skip it
  for (const p of parts.slice(1)) {
    const eq = p.indexOf("=");
    if (eq === -1) continue;
    params[p.slice(0, eq).trim()] = p.slice(eq + 1).trim();
  }
  return params;
}

// Strip [[wiki|link]] -> "link"  or  [[plain]] -> "plain"
function unlink(s: string): string {
  return s.replace(/\[\[([^\]|]+)\|([^\]]+)\]\]/g, "$2").replace(/\[\[([^\]]+)\]\]/g, "$1").trim();
}

function parsePlayer(body: string): ParsedPlayer | null {
  const params = parseParams(body);
  const posRaw = (params.pos ?? "").toUpperCase();
  if (!(posRaw in POS_TO_INT)) return null;
  // `name` keeps diacritics (e.g. "Kylian Mbappé"); `sortname` is ASCII-folded
  // ("Mbappe, Kylian"). Use sortname to count words in each side, then split
  // `name` by that count so the displayed text keeps the accents.
  const name = unlink(params.name ?? "");
  const sortname = params.sortname ?? "";
  const nameWords = name.split(/\s+/).filter(Boolean);
  let firstName = "";
  let lastName = "";
  if (sortname.includes(",")) {
    const [lastPart, firstPart] = sortname.split(",", 2);
    const lastN = lastPart.trim().split(/\s+/).filter(Boolean).length;
    const firstN = firstPart.trim().split(/\s+/).filter(Boolean).length;
    if (nameWords.length >= lastN + firstN) {
      firstName = nameWords.slice(0, firstN).join(" ");
      lastName = nameWords.slice(firstN, firstN + lastN).join(" ");
    } else {
      // sortname has more words than name (rare) — fall back to ASCII split
      lastName = lastPart.trim();
      firstName = firstPart.trim();
    }
  } else if (nameWords.length > 0) {
    // Mononymous player (e.g. Pedri) — whole name treated as last name.
    lastName = nameWords.join(" ");
    firstName = "";
  }
  return {
    no: Number(params.no ?? 0),
    pos: posRaw as ParsedPlayer["pos"],
    firstName,
    lastName,
    webName: lastName || name,
    caps: Number(params.caps ?? 0),
    goals: Number(params.goals ?? 0),
  };
}

// Heuristic price (£m). The schema stores £ × 10 as Int.
// Base by position + caps bonus (max +2.0) + goals bonus (max +4.0),
// rounded to nearest £0.5m.
function priceFor(pos: ParsedPlayer["pos"], caps: number, goals: number): number {
  const base = { GK: 4.5, DF: 5.0, MF: 6.0, FW: 7.0 }[pos];
  const capBonus = Math.min(caps * 0.02, 2.0);
  const goalBonus = Math.min(goals * 0.1, 4.0);
  const raw = base + capBonus + goalBonus;
  return Math.round(raw * 2) / 2;
}

// ── Parse the wikitext ─────────────────────────────────────────────────

console.log("[seed] fetching wikitext from en.wikipedia.org...");
const wikiRes = await fetch(WIKI_API);
if (!wikiRes.ok) {
  console.error(`[seed] wikipedia fetch failed: ${wikiRes.status} ${wikiRes.statusText}`);
  process.exit(1);
}
const snapshot = (await wikiRes.json()) as { parse: { wikitext: string } };
const wt = snapshot.parse.wikitext;
console.log(`[seed] got ${wt.length.toLocaleString()} chars`);

const nameToCode: Map<string, string> = new Map();
for (const t of WC_TEAMS) nameToCode.set(t.name, t.code);
for (const [k, v] of Object.entries(WIKI_TO_CODE)) nameToCode.set(k, v);

const sectionRe = /^===([^=]+)===$/gm;
const sections: Array<{ name: string; start: number }> = [];
let m: RegExpExecArray | null;
while ((m = sectionRe.exec(wt)) !== null) {
  sections.push({ name: m[1].trim(), start: m.index + m[0].length });
}

const squads: Map<string, ParsedPlayer[]> = new Map();
for (let i = 0; i < sections.length; i++) {
  const code = nameToCode.get(sections[i].name);
  if (!code) continue; // skips "Age", "Player representation by club", etc.
  const bodyEnd = i + 1 < sections.length ? sections[i + 1].start : wt.length;
  const body = wt.slice(sections[i].start, bodyEnd);

  const players: ParsedPlayer[] = [];
  let idx = 0;
  while (true) {
    const hit = body.indexOf("{{nat fs g player", idx);
    if (hit === -1) break;
    const tpl = readTemplate(body, hit);
    if (!tpl) break;
    const parsed = parsePlayer(tpl.body);
    if (parsed) players.push(parsed);
    idx = tpl.end;
  }
  squads.set(code, players);
}

// ── Sanity check ───────────────────────────────────────────────────────

const missing = WC_TEAMS.filter((t) => !squads.has(t.code));
if (missing.length > 0) {
  console.error("[seed] missing squads for:", missing.map((t) => t.code).join(", "));
  process.exit(1);
}
let totalPlayers = 0;
for (const [code, players] of squads) totalPlayers += players.length;
console.log(`[seed] parsed ${squads.size} squads, ${totalPlayers} players total`);

// ── Wipe player-side data and reseed ───────────────────────────────────

console.log("[seed] wiping Player and dependent rows...");
await p.$transaction([
  p.pointSnapshot.deleteMany({}),
  p.squadEntry.deleteMany({}),
  p.bid.deleteMany({}),
  p.paperTalk.deleteMany({}),
  p.player.deleteMany({}),
]);

const teamIdByCode = new Map(WC_TEAMS.map((t) => [t.code, t.id]));

console.log("[seed] inserting real player rows...");
let nextId = 1;
const rows: any[] = [];
for (const team of WC_TEAMS) {
  const players = squads.get(team.code)!;
  for (const pl of players) {
    rows.push({
      id: nextId++,
      webName: pl.webName,
      firstName: pl.firstName,
      lastName: pl.lastName,
      teamId: teamIdByCode.get(team.code)!,
      position: POS_TO_INT[pl.pos],
      nowCost: Math.round(priceFor(pl.pos, pl.caps, pl.goals) * 10),
      totalPoints: 0,
      status: "a",
      news: "",
      form: 0,
      photoCode: null,
    });
  }
}
await p.player.createMany({ data: rows });

await p.syncState.upsert({
  where: { key: "bootstrap" },
  update: { value: new Date().toISOString() },
  create: { key: "bootstrap", value: new Date().toISOString() },
});

const counts = {
  teams: await p.team.count(),
  players: await p.player.count(),
  managers: await p.manager.count(),
};
console.log("[seed] done", counts);

// Per-team breakdown so we can eyeball that nothing is off
console.log("");
console.log("Per-team player counts:");
for (const team of WC_TEAMS) {
  const n = squads.get(team.code)!.length;
  console.log(`  ${team.code}  ${team.name.padEnd(24)} ${n}`);
}

await p.$disconnect();
