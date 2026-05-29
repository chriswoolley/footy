import { useEffect, useState } from "react";
import { api, type StandingRow } from "../api";

export default function Standings() {
  const [rows, setRows] = useState<StandingRow[]>([]);

  useEffect(() => {
    api.get<StandingRow[]>("/api/standings").then(setRows);
  }, []);

  return (
    <div>
      <h2 className="text-lg font-bold mb-3">Overall Standings</h2>
      <div className="bg-white rounded shadow border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-100 text-xs uppercase text-slate-600">
            <tr>
              <th className="text-left p-2 w-12">#</th>
              <th className="text-left p-2">Manager</th>
              <th className="text-left p-2">Team</th>
              <th className="text-right p-2">Squad</th>
              <th className="text-right p-2">Score</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr>
                <td colSpan={5} className="p-4 text-center text-slate-500">
                  No managers yet.
                </td>
              </tr>
            )}
            {rows.map((r) => (
              <tr key={r.id} className="border-t border-slate-100">
                <td className="p-2 font-bold">{r.rank}</td>
                <td className="p-2">{r.username}</td>
                <td className="p-2">{r.teamName}</td>
                <td className="p-2 text-right">{r.squadSize}</td>
                <td className="p-2 text-right font-bold">{r.score}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
