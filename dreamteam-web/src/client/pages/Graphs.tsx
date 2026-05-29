import { useEffect, useMemo, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { api, type Player, type StandingRow, type GraphPoint } from "../api";

type Mode = "managers" | "player";

const COLORS = [
  "#1f6f3a", // pitch
  "#2563eb", // blue
  "#dc2626", // red
  "#ea580c", // orange
  "#9333ea", // purple
  "#0891b2", // cyan
  "#ca8a04", // amber
  "#be185d", // pink
  "#65a30d", // lime
  "#475569", // slate
];

type ManagerSeries = {
  managerId: number;
  teamName: string;
  series: GraphPoint[];
};

export default function Graphs() {
  const [mode, setMode] = useState<Mode>("managers");
  const [managers, setManagers] = useState<StandingRow[]>([]);
  const [players, setPlayers] = useState<Player[]>([]);
  const [selectedManagers, setSelectedManagers] = useState<Set<number>>(new Set());
  const [playerId, setPlayerId] = useState<number | "">("");
  const [managerSeries, setManagerSeries] = useState<ManagerSeries[]>([]);
  const [playerSeries, setPlayerSeries] = useState<{
    name: string;
    series: GraphPoint[];
  } | null>(null);

  useEffect(() => {
    api.get<StandingRow[]>("/api/standings").then((rows) => {
      setManagers(rows);
      // Default: top 3 managers selected
      setSelectedManagers(new Set(rows.slice(0, 3).map((r) => r.id)));
    });
    api.get<Player[]>("/api/players?").then((all) =>
      setPlayers(all.sort((a, b) => b.points - a.points).slice(0, 200)),
    );
  }, []);

  // Fetch series for every selected manager
  useEffect(() => {
    if (mode !== "managers") return;
    const ids = [...selectedManagers];
    if (ids.length === 0) {
      setManagerSeries([]);
      return;
    }
    let cancelled = false;
    Promise.all(
      ids.map((id) =>
        api
          .get<{ manager: { teamName: string } | null; series: GraphPoint[] }>(
            `/api/graphs/manager/${id}`,
          )
          .then((r) => ({
            managerId: id,
            teamName: r.manager?.teamName ?? `#${id}`,
            series: r.series,
          })),
      ),
    ).then((results) => {
      if (!cancelled) setManagerSeries(results);
    });
    return () => {
      cancelled = true;
    };
  }, [mode, selectedManagers]);

  // Fetch player series
  useEffect(() => {
    if (mode !== "player" || !playerId) {
      setPlayerSeries(null);
      return;
    }
    api
      .get<{ player: { name: string; team: string } | null; series: GraphPoint[] }>(
        `/api/graphs/player/${playerId}`,
      )
      .then((r) => {
        setPlayerSeries(
          r.player ? { name: `${r.player.name} (${r.player.team})`, series: r.series } : null,
        );
      });
  }, [mode, playerId]);

  // Build merged datasets for the two charts
  const { weeklyData, cumulativeData, seriesKeys } = useMemo(() => {
    if (mode !== "managers") {
      return { weeklyData: [], cumulativeData: [], seriesKeys: [] as string[] };
    }
    const allGws = new Set<number>();
    for (const m of managerSeries) for (const p of m.series) allGws.add(p.gameweek);
    const gws = [...allGws].sort((a, b) => a - b);
    const keys = managerSeries.map((m) => m.teamName);

    const weekly = gws.map((gw) => {
      const row: Record<string, number | string> = { gameweek: `GW${gw}` };
      for (const m of managerSeries) {
        const point = m.series.find((p) => p.gameweek === gw);
        row[m.teamName] = point?.points ?? 0;
      }
      return row;
    });

    const cumulative = gws.map((gw, idx) => {
      const row: Record<string, number | string> = { gameweek: `GW${gw}` };
      for (const m of managerSeries) {
        let running = 0;
        for (let i = 0; i <= idx; i++) {
          const point = m.series.find((p) => p.gameweek === gws[i]);
          running += point?.points ?? 0;
        }
        row[m.teamName] = running;
      }
      return row;
    });

    return { weeklyData: weekly, cumulativeData: cumulative, seriesKeys: keys };
  }, [mode, managerSeries]);

  function toggleManager(id: number) {
    setSelectedManagers((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  return (
    <div>
      <h2 className="text-lg font-bold mb-3">Graphs</h2>
      <div className="flex flex-wrap gap-2 mb-4 items-center">
        <select
          className="border rounded px-2 py-1 text-sm"
          value={mode}
          onChange={(e) => setMode(e.target.value as Mode)}
        >
          <option value="managers">Managers — compare teams</option>
          <option value="player">Player points per gameweek</option>
        </select>
        {mode === "player" && (
          <select
            className="border rounded px-2 py-1 text-sm flex-1 min-w-[260px]"
            value={playerId}
            onChange={(e) => setPlayerId(e.target.value ? Number(e.target.value) : "")}
          >
            <option value="">Pick a player…</option>
            {players.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} — {p.teamShort} ({p.points} pts)
              </option>
            ))}
          </select>
        )}
      </div>

      {mode === "managers" && (
        <>
          <div className="bg-white rounded shadow border border-slate-200 p-4 mb-4">
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-sm font-medium text-slate-600">Managers</h3>
              <div className="text-xs flex gap-3 text-slate-500">
                <button
                  onClick={() => setSelectedManagers(new Set(managers.map((m) => m.id)))}
                  className="hover:underline"
                >
                  Select all
                </button>
                <button
                  onClick={() => setSelectedManagers(new Set())}
                  className="hover:underline"
                >
                  Clear
                </button>
              </div>
            </div>
            <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-1">
              {managers.map((m) => {
                const colorIdx = [...selectedManagers].indexOf(m.id);
                const swatchColor =
                  colorIdx >= 0 ? COLORS[colorIdx % COLORS.length] : "#cbd5e1";
                return (
                  <label
                    key={m.id}
                    className="flex items-center gap-2 px-2 py-1 rounded hover:bg-slate-50 cursor-pointer text-sm"
                  >
                    <input
                      type="checkbox"
                      checked={selectedManagers.has(m.id)}
                      onChange={() => toggleManager(m.id)}
                    />
                    <span
                      className="w-3 h-3 rounded-full inline-block flex-shrink-0"
                      style={{ background: swatchColor }}
                    />
                    <span className="truncate">{m.teamName}</span>
                  </label>
                );
              })}
            </div>
          </div>

          <ChartCard
            title="Weekly points"
            data={weeklyData}
            seriesKeys={seriesKeys}
            empty="Pick one or more managers above to compare their gameweek-by-gameweek points."
          />
          <div className="h-4" />
          <ChartCard
            title="Cumulative points"
            data={cumulativeData}
            seriesKeys={seriesKeys}
            empty=""
          />
        </>
      )}

      {mode === "player" && (
        <div className="bg-white rounded shadow border border-slate-200 p-4">
          <h3 className="text-sm font-medium text-slate-600 mb-2">
            {playerSeries?.name ?? "—"}
          </h3>
          <div style={{ width: "100%", height: 360 }}>
            <ResponsiveContainer>
              <LineChart
                data={(playerSeries?.series ?? []).map((s) => ({
                  gameweek: `GW${s.gameweek}`,
                  points: s.points,
                  value: s.value,
                }))}
              >
                <CartesianGrid stroke="#e2e8f0" strokeDasharray="3 3" />
                <XAxis dataKey="gameweek" />
                <YAxis />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="points" stroke="#1f6f3a" strokeWidth={2} dot />
                <Line
                  type="monotone"
                  dataKey="value"
                  stroke="#94a3b8"
                  strokeWidth={1}
                  dot={false}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
          {!playerSeries && (
            <p className="text-sm text-slate-500 text-center mt-4">
              Pick a player to chart their points by gameweek.
            </p>
          )}
        </div>
      )}
    </div>
  );
}

function ChartCard({
  title,
  data,
  seriesKeys,
  empty,
}: {
  title: string;
  data: Array<Record<string, number | string>>;
  seriesKeys: string[];
  empty: string;
}) {
  return (
    <div className="bg-white rounded shadow border border-slate-200 p-4">
      <h3 className="text-sm font-medium text-slate-600 mb-2">{title}</h3>
      <div style={{ width: "100%", height: 320 }}>
        <ResponsiveContainer>
          <LineChart data={data}>
            <CartesianGrid stroke="#e2e8f0" strokeDasharray="3 3" />
            <XAxis dataKey="gameweek" />
            <YAxis />
            <Tooltip />
            <Legend />
            {seriesKeys.map((key, idx) => (
              <Line
                key={key}
                type="monotone"
                dataKey={key}
                stroke={COLORS[idx % COLORS.length]}
                strokeWidth={2}
                dot={false}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      </div>
      {data.length === 0 && empty && (
        <p className="text-sm text-slate-500 text-center mt-2">{empty}</p>
      )}
    </div>
  );
}
