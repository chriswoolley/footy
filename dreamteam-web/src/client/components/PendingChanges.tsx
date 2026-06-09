import { useEffect, useState } from "react";
import { api } from "../api";

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

type Side = {
  playerId: number;
  name: string;
  teamShort: string;
  position: number;
  photoUrl: string | null;
} | null;

export type PendingRow = {
  id: number;
  kind: "PLAY" | "BENCH";
  toSlot: number | null;
  effectiveAt: string;
  createdAt: string;
  incoming: Side;
  outgoing: Side;
};

type Props = {
  rows: PendingRow[];
  /** Parent reloads after cancel. */
  onChanged: () => void;
};

export function PendingChanges({ rows, onChanged }: Props) {
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  async function cancel(id: number) {
    await api.del(`/api/squad/pending/${id}`);
    onChanged();
  }

  if (rows.length === 0) {
    return (
      <p className="text-xs text-slate-500 italic">
        No pending changes. Play / bench actions apply at the next 01:00 UTC.
      </p>
    );
  }

  return (
    <div className="space-y-2">
      <div className="text-xs text-slate-500">
        Team-selection changes apply at the next 01:00 UTC. Cancel here before that.
      </div>
      <ul className="space-y-2">
        {rows.map((r) => {
          const ms = new Date(r.effectiveAt).getTime() - now;
          const seconds = Math.max(0, Math.floor(ms / 1000));
          const h = Math.floor(seconds / 3600);
          const m = Math.floor((seconds % 3600) / 60);
          const s = seconds % 60;
          const countdown = [h, m, s].map((n) => n.toString().padStart(2, "0")).join(":");
          const isPlay = r.kind === "PLAY";
          return (
            <li
              key={r.id}
              className={`flex items-center gap-3 text-sm rounded px-3 py-2 border ${
                isPlay
                  ? "bg-emerald-50 border-emerald-200"
                  : "bg-amber-50 border-amber-200"
              }`}
            >
              <span
                className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded ${
                  isPlay ? "bg-emerald-600 text-white" : "bg-amber-600 text-white"
                }`}
              >
                {isPlay ? "Play" : "Bench"}
              </span>

              {/* Outgoing — the one going off the pitch */}
              {r.outgoing && (
                <PlayerBadge
                  side={r.outgoing}
                  direction="out"
                  emptyLabel={isPlay ? "empty slot" : undefined}
                />
              )}

              {/* Arrow between the two */}
              {isPlay && (
                <span className="text-slate-400 text-lg select-none" aria-hidden>
                  →
                </span>
              )}

              {/* Incoming — only for PLAY */}
              {r.incoming && <PlayerBadge side={r.incoming} direction="in" />}

              {/* For PLAY without an existing occupant, still show the
                  incoming on its own (the outgoing column is empty). */}
              {!r.outgoing && isPlay && r.incoming && null}

              {isPlay && r.toSlot != null && (
                <span className="text-xs text-emerald-700 ml-1">slot {r.toSlot}</span>
              )}

              <span className="ml-auto font-mono text-xs text-slate-500 tabular-nums">
                {countdown}
              </span>
              <button
                onClick={() => cancel(r.id)}
                className="text-xs text-red-600 hover:underline"
              >
                cancel
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function PlayerBadge({
  side,
  direction,
  emptyLabel,
}: {
  side: NonNullable<Side>;
  direction: "in" | "out";
  emptyLabel?: string;
}) {
  // The little corner arrow indicates direction of travel — green ↑ for the
  // incoming player (joining the XI), red ↓ for the outgoing (going to the
  // bench). Drops to a label-only badge if no player exists in that role.
  if (!side) {
    return <span className="text-xs text-slate-400 italic">{emptyLabel ?? "—"}</span>;
  }
  const arrowCls =
    direction === "in"
      ? "bg-emerald-600 text-white"
      : "bg-red-600 text-white";
  return (
    <div className="flex items-center gap-2">
      <div className="relative w-9 h-9 rounded-full bg-white overflow-hidden border border-slate-300 shrink-0">
        {side.photoUrl ? (
          <img
            src={side.photoUrl}
            alt={side.name}
            className="w-full h-full object-cover object-top"
            loading="lazy"
            onError={(ev) => {
              (ev.currentTarget as HTMLImageElement).style.display = "none";
            }}
          />
        ) : (
          <span className="flex items-center justify-center w-full h-full text-[10px] font-bold text-slate-700">
            {side.teamShort}
          </span>
        )}
        <span
          className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full flex items-center justify-center text-[11px] leading-none font-bold shadow ${arrowCls}`}
          title={direction === "in" ? "Coming on" : "Going off"}
        >
          {direction === "in" ? "↑" : "↓"}
        </span>
      </div>
      <div className="flex flex-col leading-tight">
        <span className="text-xs font-semibold truncate max-w-[110px]">{side.name}</span>
        <span className="text-[10px] text-slate-500">
          {POS_NAME[side.position as 1 | 2 | 3 | 4]} · {side.teamShort}
        </span>
      </div>
    </div>
  );
}
