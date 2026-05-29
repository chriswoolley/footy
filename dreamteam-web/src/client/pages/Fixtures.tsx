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

export default function Fixtures() {
  const [byDay, setByDay] = useState<GroupedFixtures>({});
  const [filter, setFilter] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<GroupedFixtures>("/api/admin/fixtures")
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
            {isPl ? "fantasy.premierleague.com" : "openfootball/worldcup.json"}.
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
                      <td className="p-2 text-xs text-slate-500">
                        {f.group ?? f.round}
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
