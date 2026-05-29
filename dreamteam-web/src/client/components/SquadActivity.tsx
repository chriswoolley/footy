import { useEffect, useMemo, useState } from "react";
import { api } from "../api";
import { useSorted, sortableHeaderProps } from "../hooks/useSorted";

const POSITION_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

type ActivityRow = {
  when: string;
  kind: "signed" | "sold" | "outbid" | "pending";
  playerId: number;
  playerName: string;
  playerTeamShort: string;
  position: 1 | 2 | 3 | 4;
  amount: number;
  bidPrice?: number;
  delta?: number;
};

const KIND_STYLE: Record<ActivityRow["kind"], string> = {
  signed: "bg-emerald-100 text-emerald-800",
  sold: "bg-red-100 text-red-700",
  outbid: "bg-slate-200 text-slate-600",
  pending: "bg-amber-100 text-amber-800",
};

const KIND_LABEL: Record<ActivityRow["kind"], string> = {
  signed: "Signed",
  sold: "Sold",
  outbid: "Outbid",
  pending: "Pending",
};

export function SquadActivity() {
  const [rows, setRows] = useState<ActivityRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api
      .get<ActivityRow[]>("/api/squad/activity")
      .then(setRows)
      .finally(() => setLoading(false));
  }, []);

  const columns = useMemo(
    () => ({
      when: (r: ActivityRow) => new Date(r.when),
      kind: (r: ActivityRow) => r.kind,
      playerName: (r: ActivityRow) => r.playerName,
      playerTeamShort: (r: ActivityRow) => r.playerTeamShort,
      position: (r: ActivityRow) => r.position,
      amount: (r: ActivityRow) => r.amount,
      bidPrice: (r: ActivityRow) => r.bidPrice ?? null,
      delta: (r: ActivityRow) => r.delta ?? null,
    }),
    [],
  );
  const { sorted, toggle, indicator } = useSorted(rows, columns, {
    key: "when",
    dir: "desc",
  });

  if (loading) return <p className="text-sm text-slate-500">Loading activity…</p>;
  if (rows.length === 0)
    return <p className="text-sm text-slate-500">No bidding or selling activity yet.</p>;

  const signed = rows.filter((r) => r.kind === "signed").length;
  const sold = rows.filter((r) => r.kind === "sold").length;
  const realisedLoss = rows
    .filter((r) => r.kind === "sold")
    .reduce((s, r) => s + (r.delta ?? 0), 0);

  return (
    <div>
      <div className="flex items-center justify-between mb-2 flex-wrap gap-2">
        <h3 className="font-bold">Bidding &amp; selling log</h3>
        <div className="text-xs text-slate-500">
          <span className="text-emerald-700 font-semibold">{signed}</span> signings ·{" "}
          <span className="text-red-700 font-semibold">{sold}</span> sells · realised{" "}
          <span
            className={realisedLoss >= 0 ? "text-emerald-700 font-semibold" : "text-red-700 font-semibold"}
          >
            {realisedLoss >= 0 ? "+" : "−"}£{Math.abs(realisedLoss).toFixed(1)}m
          </span>
        </div>
      </div>
      <div className="overflow-x-auto max-h-[420px] overflow-y-auto border border-slate-200 rounded">
        <table className="w-full text-sm">
          <thead className="text-xs uppercase text-slate-500 sticky top-0 bg-slate-50 border-b border-slate-200">
            <tr>
              <th {...sortableHeaderProps(toggle, "when", "text-left p-2")}>
                When{indicator("when")}
              </th>
              <th {...sortableHeaderProps(toggle, "kind", "text-left p-2")}>
                Type{indicator("kind")}
              </th>
              <th {...sortableHeaderProps(toggle, "playerName", "text-left p-2")}>
                Player{indicator("playerName")}
              </th>
              <th {...sortableHeaderProps(toggle, "playerTeamShort", "text-left p-2")}>
                Club{indicator("playerTeamShort")}
              </th>
              <th {...sortableHeaderProps(toggle, "position", "text-left p-2")}>
                Pos{indicator("position")}
              </th>
              <th
                title="What was paid (for Signed) or received (for Sold)"
                {...sortableHeaderProps(toggle, "amount", "text-right p-2")}
              >
                Price{indicator("amount")}
              </th>
              <th
                title="For sells: original buy price"
                {...sortableHeaderProps(toggle, "bidPrice", "text-right p-2")}
              >
                Paid{indicator("bidPrice")}
              </th>
              <th
                title="For sells: sellPrice − bid (negative = loss)"
                {...sortableHeaderProps(toggle, "delta", "text-right p-2")}
              >
                Δ{indicator("delta")}
              </th>
            </tr>
          </thead>
          <tbody>
            {sorted.map((r, i) => (
              <tr
                key={`${r.kind}-${r.playerId}-${r.when}-${i}`}
                className="border-t border-slate-100 hover:bg-slate-50"
              >
                <td className="p-2 text-xs text-slate-500 whitespace-nowrap tabular-nums">
                  {new Date(r.when).toLocaleString()}
                </td>
                <td className="p-2">
                  <span
                    className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded ${KIND_STYLE[r.kind]}`}
                  >
                    {KIND_LABEL[r.kind]}
                  </span>
                </td>
                <td className="p-2 font-medium">{r.playerName}</td>
                <td className="p-2">{r.playerTeamShort}</td>
                <td className="p-2 text-xs text-slate-500">
                  {POSITION_NAME[r.position]}
                </td>
                <td className="p-2 text-right tabular-nums">
                  £{r.amount.toFixed(1)}m
                </td>
                <td className="p-2 text-right tabular-nums text-slate-500">
                  {r.bidPrice != null ? `£${r.bidPrice.toFixed(1)}m` : "—"}
                </td>
                <td className="p-2 text-right tabular-nums text-xs">
                  {r.delta != null ? (
                    <span
                      className={
                        r.delta > 0
                          ? "text-emerald-600"
                          : r.delta < 0
                            ? "text-red-600"
                            : "text-slate-400"
                      }
                    >
                      {r.delta > 0 ? "+" : ""}
                      £{Math.abs(r.delta).toFixed(1)}m
                    </span>
                  ) : (
                    "—"
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
