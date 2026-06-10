import { useEffect, useMemo, useState } from "react";
import { api } from "../api";

type Fixture = {
  round: string;
  date: string;
  time?: string;
  team1: string;
  team2: string;
  group?: string;
  ground?: string;
};

type GroupedFixtures = Record<string, Fixture[]>;

// Distinct, consistent colour per round label so fixtures in the same round
// are easy to spot. Classes are literal strings so Tailwind keeps them.
const ROUND_COLORS = [
  "bg-blue-100 text-blue-800 border-blue-200",
  "bg-emerald-100 text-emerald-800 border-emerald-200",
  "bg-amber-100 text-amber-800 border-amber-200",
  "bg-violet-100 text-violet-800 border-violet-200",
  "bg-rose-100 text-rose-800 border-rose-200",
  "bg-cyan-100 text-cyan-800 border-cyan-200",
  "bg-lime-100 text-lime-800 border-lime-200",
  "bg-fuchsia-100 text-fuchsia-800 border-fuchsia-200",
  "bg-orange-100 text-orange-800 border-orange-200",
  "bg-teal-100 text-teal-800 border-teal-200",
];
function roundColor(round: string): string {
  let h = 0;
  for (let i = 0; i < round.length; i++) h = (h * 31 + round.charCodeAt(i)) >>> 0;
  return ROUND_COLORS[h % ROUND_COLORS.length];
}

export default function Fixtures() {
  const [byDay, setByDay] = useState<GroupedFixtures>({});
  const [filter, setFilter] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<GroupedFixtures>("/api/fixtures")
      .then((data) => setByDay(data))
      .finally(() => setLoading(false));
  }, []);

  const days = useMemo(() => Object.keys(byDay).sort(), [byDay]);

  // Detect competition from a sample fixture's round label.
  const isPl = useMemo(() => {
    for (const list of Object.values(byDay)) {
      for (const f of list) if (/^GW\d+/i.test(f.round)) return true;
    }
    return false;
  }, [byDay]);

  const visible = useMemo(() => {
    if (!filter) return days;
    const q = filter.toLowerCase();
    return days.filter((d) =>
      byDay[d].some(
        (f) =>
          f.team1.toLowerCase().includes(q) ||
          f.team2.toLowerCase().includes(q) ||
          (f.group ?? "").toLowerCase().includes(q) ||
          (f.ground ?? "").toLowerCase().includes(q) ||
          f.round.toLowerCase().includes(q),
      ),
    );
  }, [days, byDay, filter]);

  const matchCount = Object.values(byDay).reduce((s, day) => s + day.length, 0);

  return (
    <div>
      <div className="flex items-center justify-between mb-3 gap-3 flex-wrap">
        <div>
          <h2 className="text-lg font-bold">
            {isPl ? "Premier League — Fixtures" : "World Cup 2026 — Fixtures"}
          </h2>
          <p className="text-sm text-slate-500">
            {matchCount} matches across {days.length} match days, sourced from{" "}
            {isPl ? "fantasy.premierleague.com" : "play.fifa.com (FIFA WC Fantasy)"}.
          </p>
        </div>
        <input
          className="border rounded px-2 py-1 text-sm min-w-[200px]"
          placeholder="Filter by team, group, round, venue…"
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
        />
      </div>

      {loading ? (
        <p className="text-slate-500">Loading fixtures…</p>
      ) : visible.length === 0 ? (
        <p className="text-slate-500">No matches match that filter.</p>
      ) : (
        <div className="space-y-4">
          {visible.map((day) => (
            <div key={day} className="bg-white rounded shadow border border-slate-200">
              <div className="px-3 py-2 border-b border-slate-200 bg-slate-50 flex items-center justify-between">
                <h3 className="font-bold">
                  {new Date(day).toLocaleDateString(undefined, {
                    weekday: "short",
                    year: "numeric",
                    month: "short",
                    day: "numeric",
                  })}
                </h3>
                <span className="text-xs text-slate-500">
                  {byDay[day].length} match{byDay[day].length === 1 ? "" : "es"}
                </span>
              </div>
              <table className="w-full text-sm">
                <tbody>
                  {byDay[day].map((f, i) => (
                    <tr key={i} className="border-t border-slate-100 first:border-t-0">
                      <td className="p-2 text-slate-500 text-xs whitespace-nowrap w-32">
                        {f.time ?? "—"}
                      </td>
                      <td className="p-2 text-right font-medium">{f.team1}</td>
                      <td className="p-2 text-center text-slate-400 text-xs">vs</td>
                      <td className="p-2 font-medium">{f.team2}</td>
                      <td className="p-2 whitespace-nowrap">
                        <span
                          className={`inline-block px-2 py-0.5 rounded border text-xs font-semibold ${roundColor(
                            f.round,
                          )}`}
                          title={`Round: ${f.round}`}
                        >
                          {f.round}
                        </span>
                        {f.group && (
                          <span className="ml-1 inline-block px-1.5 py-0.5 rounded border border-slate-200 bg-slate-100 text-slate-600 text-[11px]">
                            Grp {f.group}
                          </span>
                        )}
                      </td>
                      <td className="p-2 text-xs text-slate-400 hidden md:table-cell">
                        {f.ground ?? ""}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
