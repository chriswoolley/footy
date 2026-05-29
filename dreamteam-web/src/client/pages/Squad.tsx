import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, type Squad as SquadDTO } from "../api";
import { useAuth } from "../auth";
import { Pitch } from "../components/Pitch";
import { Dugout } from "../components/Dugout";
import { SquadActivity } from "../components/SquadActivity";

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

export default function Squad() {
  const { me, refresh: refreshMe } = useAuth();
  const [squad, setSquad] = useState<SquadDTO | null>(null);
  const [err, setErr] = useState<string | null>(null);

  async function load() {
    try {
      const s = await api.get<SquadDTO>("/api/squad");
      setSquad(s);
    } catch (e: any) {
      setErr(e.message);
    }
  }

  useEffect(() => {
    load();
  }, []);

  async function setFormation(f: "442" | "433") {
    await api.post("/api/squad/formation", { formation: f });
    await refreshMe();
    load();
  }

  async function dropOnSlot(playerId: number, slot: number) {
    try {
      await api.post("/api/squad/play", { playerId, slot });
      load();
    } catch (e: any) {
      setErr(e.message);
    }
  }

  async function bench(playerId: number) {
    await api.post("/api/squad/bench", { playerId });
    load();
  }

  async function release(playerId: number) {
    if (!confirm("Sell this player?")) return;
    await api.del(`/api/squad/${playerId}`);
    load();
  }

  if (!squad || !me) return <div>Loading squad…</div>;

  const benched = squad.entries.filter((e) => !e.playing);

  return (
    <div className="space-y-6">
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-lg font-bold">Pitch</h2>
          <div className="flex gap-1 text-sm">
            <button
              onClick={() => setFormation("442")}
              className={`px-3 py-1 rounded ${
                me.formation === "442" ? "bg-slate-900 text-white" : "bg-slate-200"
              }`}
            >
              1-4-4-2
            </button>
            <button
              onClick={() => setFormation("433")}
              className={`px-3 py-1 rounded ${
                me.formation === "433" ? "bg-slate-900 text-white" : "bg-slate-200"
              }`}
            >
              1-4-3-3
            </button>
          </div>
        </div>
        <div className="flex gap-3 items-stretch">
          <div className="flex-1 min-w-0">
            <Pitch
              formation={me.formation}
              entries={squad.entries}
              onDropOnSlot={dropOnSlot}
              onBench={bench}
            />
          </div>
          <div className="w-32 flex-shrink-0">
            <Dugout bench={benched} onBench={bench} />
          </div>
        </div>
        <div className="mt-4 flex justify-between text-sm">
          <span>
            Budget: <strong>£{squad.budget.toFixed(1)}m</strong>
          </span>
          <span>
            Spent: <strong>£{squad.spent.toFixed(1)}m</strong>
          </span>
          <span>
            Balance: <strong>£{squad.balance.toFixed(1)}m</strong>
          </span>
        </div>
        {err && <div className="mt-2 text-red-600 text-sm">{err}</div>}
      </div>

      <div>
        <h2 className="text-lg font-bold mb-3">Squad</h2>
        {squad.entries.length === 0 ? (
          <p className="text-sm text-slate-500">
            No players yet — visit the <Link className="text-blue-600 underline" to="/market">market</Link> to sign some.
          </p>
        ) : (
          <table className="w-full text-sm">
            <thead className="text-xs text-slate-500 uppercase">
              <tr>
                <th className="text-left py-1">Pos</th>
                <th className="text-left py-1">Player</th>
                <th className="text-left py-1">Team</th>
                <th className="text-right py-1" title="What you paid (winning bid)">
                  Paid
                </th>
                <th className="text-right py-1" title="Current book / market value">
                  Book
                </th>
                <th
                  className="text-right py-1"
                  title="Profit/loss = current book − price paid"
                >
                  Δ
                </th>
                <th className="text-right py-1">Pts</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {squad.entries.map((e) => {
                const delta = e.price - e.bid;
                const sign = delta > 0 ? "+" : "";
                const deltaColor =
                  delta > 0 ? "text-emerald-600" : delta < 0 ? "text-red-600" : "text-slate-400";
                return (
                  <tr
                    key={e.id}
                    draggable
                    onDragStart={(ev) =>
                      ev.dataTransfer.setData("text/plain", String(e.playerId))
                    }
                    className={`border-t border-slate-200 ${e.playing ? "" : "bg-slate-50"}`}
                  >
                    <td className="py-1">{POS_NAME[e.position]}</td>
                    <td className="py-1 font-medium">{e.name}</td>
                    <td className="py-1">{e.teamShort}</td>
                    <td className="py-1 text-right tabular-nums">
                      £{e.bid.toFixed(1)}m
                    </td>
                    <td className="py-1 text-right tabular-nums">
                      £{e.price.toFixed(1)}m
                    </td>
                    <td
                      className={`py-1 text-right tabular-nums text-xs ${deltaColor}`}
                    >
                      {sign}
                      £{Math.abs(delta).toFixed(1)}m
                    </td>
                    <td className="py-1 text-right">{e.points}</td>
                    <td className="py-1 text-right">
                      <button
                        onClick={() => release(e.playerId)}
                        className="text-red-600 hover:underline text-xs"
                      >
                        Sell
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
        <p className="mt-3 text-xs text-slate-500">
          Drag a player from the dugout onto the pitch. Drag a pitch player onto the dugout (or double-click) to bench.
        </p>
      </div>
    </div>

    <section className="bg-white rounded shadow border border-slate-200 p-4">
      <SquadActivity />
    </section>
    </div>
  );
}
