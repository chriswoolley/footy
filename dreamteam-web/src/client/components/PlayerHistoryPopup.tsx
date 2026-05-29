import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { api } from "../api";

type HistoryRow = {
  gameweek: number;
  kickoffTime: string | null;
  points: number;
  owned: boolean;
  playing: boolean;
  credited: number;
};

type HistoryData = {
  player: { id: number; name: string; team: string; teamShort: string; position: number };
  history: HistoryRow[];
  totalScored: number;
  totalCredited: number;
};

// Module-level cache so re-hovering the same player on the same page-load is instant.
const cache = new Map<number, HistoryData>();

type Props = {
  playerId: number;
  children: React.ReactNode;
};

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

export function PlayerHistoryPopup({ playerId, children }: Props) {
  const [open, setOpen] = useState(false);
  const [data, setData] = useState<HistoryData | null>(cache.get(playerId) ?? null);
  const [anchor, setAnchor] = useState<{ left: number; top: number; w: number } | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Fetch lazily the first time we open for this player.
  useEffect(() => {
    if (!open) return;
    if (cache.has(playerId)) {
      setData(cache.get(playerId)!);
      return;
    }
    api
      .get<HistoryData>(`/api/squad/player-history/${playerId}`)
      .then((d) => {
        cache.set(playerId, d);
        setData(d);
      })
      .catch(() => {
        /* ignore — popup will show a "no data" message */
      });
  }, [open, playerId]);

  function handleEnter() {
    const el = containerRef.current;
    if (el) {
      const rect = el.getBoundingClientRect();
      setAnchor({ left: rect.left + rect.width / 2, top: rect.bottom + 8, w: rect.width });
    }
    setOpen(true);
  }

  return (
    <>
      <div
        ref={containerRef}
        onMouseEnter={handleEnter}
        onMouseLeave={() => setOpen(false)}
        className="flex flex-col items-center"
      >
        {children}
      </div>
      {open && anchor && createPortal(<PopupCard anchor={anchor} data={data} />, document.body)}
    </>
  );
}

function PopupCard({
  anchor,
  data,
}: {
  anchor: { left: number; top: number; w: number };
  data: HistoryData | null;
}) {
  // Clamp horizontally to stay on-screen.
  const popupWidth = 380;
  let left = anchor.left - popupWidth / 2;
  if (left < 8) left = 8;
  if (typeof window !== "undefined" && left + popupWidth > window.innerWidth - 8) {
    left = window.innerWidth - popupWidth - 8;
  }

  const style: React.CSSProperties = {
    position: "fixed",
    left,
    top: anchor.top,
    width: popupWidth,
    zIndex: 1000,
    pointerEvents: "none",
  };

  if (!data) {
    return (
      <div
        style={style}
        className="bg-white rounded-md shadow-2xl border border-slate-300 p-3 text-xs text-slate-500"
      >
        Loading history…
      </div>
    );
  }

  const seasonGws = 38;
  const byGw = new Map(data.history.map((r) => [r.gameweek, r]));

  return (
    <div
      style={style}
      className="bg-white rounded-md shadow-2xl border border-slate-300 overflow-hidden"
    >
      <div className="bg-brand-navy text-white px-3 py-2 flex items-baseline gap-2">
        <span className="font-bold">{data.player.name}</span>
        <span className="text-xs text-brand-cyan">
          {POS_NAME[data.player.position as 1 | 2 | 3 | 4]} · {data.player.teamShort}
        </span>
      </div>

      <div className="grid grid-cols-[repeat(19,minmax(0,1fr))] gap-px bg-slate-200 p-px text-[10px]">
        {Array.from({ length: seasonGws }, (_, i) => i + 1).map((gw) => {
          const row = byGw.get(gw);
          // Colour scheme:
          //  - starting + scored points → green
          //  - starting + 0 → light green
          //  - owned but benched → amber
          //  - not owned → light grey
          //  - no data for that GW → faint
          let cls = "bg-slate-100 text-slate-400";
          if (!row) {
            cls = "bg-slate-50 text-slate-300";
          } else if (row.playing && row.credited > 0) {
            cls = "bg-emerald-500 text-white font-bold";
          } else if (row.playing) {
            cls = "bg-emerald-100 text-emerald-800";
          } else if (row.owned) {
            cls = "bg-amber-500 text-white font-semibold";
          }
          return (
            <div
              key={gw}
              className={`flex flex-col items-center justify-center py-1 ${cls}`}
              title={
                row
                  ? `GW${gw}: ${row.points} pts ${row.playing ? "(in XI — credited)" : row.owned ? "(benched)" : "(not owned)"}`
                  : `GW${gw}: no data`
              }
            >
              <span className="opacity-60 leading-none">{gw}</span>
              <span className="leading-none mt-0.5">{row ? row.points : "—"}</span>
            </div>
          );
        })}
      </div>

      <div className="px-3 py-2 flex items-center justify-between text-xs border-t border-slate-200 bg-slate-50">
        <div className="flex gap-3">
          <span>
            <span className="text-slate-500">Scored:</span>{" "}
            <strong>{data.totalScored}</strong> pts
          </span>
          <span>
            <span className="text-slate-500">For you:</span>{" "}
            <strong className="text-emerald-700">{data.totalCredited}</strong> pts
          </span>
        </div>
      </div>

      <div className="px-3 py-1 text-[10px] flex gap-2 border-t border-slate-200 bg-white">
        <Legend cls="bg-emerald-500" label="in XI" />
        <Legend cls="bg-emerald-100" label="XI · 0 pts" />
        <Legend cls="bg-amber-500" label="benched" />
        <Legend cls="bg-slate-100" label="not owned" />
      </div>
    </div>
  );
}

function Legend({ cls, label }: { cls: string; label: string }) {
  return (
    <span className="inline-flex items-center gap-1 text-slate-500">
      <span className={`inline-block w-2 h-2 rounded-sm ${cls}`} />
      {label}
    </span>
  );
}
