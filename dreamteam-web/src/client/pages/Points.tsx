import { useEffect, useState } from "react";
import { api } from "../api";

type LeaderboardRow = {
  id: number;
  name: string;
  team: string;
  position: number;
  points: number;
  price: number;
};

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

export default function Points() {
  const [top, setTop] = useState<LeaderboardRow[]>([]);

  useEffect(() => {
    api.get<LeaderboardRow[]>("/api/graphs/leaderboard").then(setTop);
  }, []);

  return (
    <div>
      <h2 className="text-lg font-bold mb-3">Points Leaderboard</h2>
      <p className="text-sm text-slate-500 mb-3">
        Top 20 scoring players this tournament. Empty until the World Cup kicks off
        on 11 June 2026.
      </p>
      <div className="bg-white rounded shadow border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-100 text-xs uppercase text-slate-600">
            <tr>
              <th className="text-left p-2 w-10">#</th>
              <th className="text-left p-2">Player</th>
              <th className="text-left p-2">Team</th>
              <th className="text-left p-2">Pos</th>
              <th className="text-right p-2">Price</th>
              <th className="text-right p-2">Points</th>
            </tr>
          </thead>
          <tbody>
            {top.map((p, i) => (
              <tr key={p.id} className="border-t border-slate-100">
                <td className="p-2">{i + 1}</td>
                <td className="p-2 font-medium">{p.name}</td>
                <td className="p-2">{p.team}</td>
                <td className="p-2">{POS_NAME[p.position as 1 | 2 | 3 | 4]}</td>
                <td className="p-2 text-right">£{p.price.toFixed(1)}m</td>
                <td className="p-2 text-right font-bold">{p.points}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
