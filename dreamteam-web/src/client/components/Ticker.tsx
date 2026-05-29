import { useEffect, useState } from "react";
import { api } from "../api";
import { BrandBgLayers } from "./BrandBgLayers";

type Transfer = { player: string; team: string; amount: number; when: string };
type TickerData = {
  serverTime: string;
  nextDeadline: string;
  secondsUntilBidEnds: number;
  transfers: Transfer[];
};

function fmtHMS(totalSeconds: number): string {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  return [h, m, s].map((n) => n.toString().padStart(2, "0")).join(":");
}

export function Ticker() {
  const [data, setData] = useState<TickerData | null>(null);
  const [now, setNow] = useState(Date.now());

  useEffect(() => {
    let stopped = false;
    async function fetchOnce() {
      try {
        const d = await api.get<TickerData>("/api/ticker");
        if (!stopped) setData(d);
      } catch {
        // ignore — keep previous data
      }
    }
    fetchOnce();
    const poll = setInterval(fetchOnce, 30_000);
    const tick = setInterval(() => setNow(Date.now()), 1000);
    return () => {
      stopped = true;
      clearInterval(poll);
      clearInterval(tick);
    };
  }, []);

  const remaining = data
    ? Math.max(0, Math.floor((new Date(data.nextDeadline).getTime() - now) / 1000))
    : 0;

  const transfers = data?.transfers ?? [];
  // Duplicate the list so the CSS `translateX(-50%)` keyframe loops seamlessly.
  const doubled = transfers.concat(transfers);

  return (
    <div className="brand-bg text-white text-sm border-t-2 border-brand-cyan shadow-inner">
      <BrandBgLayers />
      <div className="max-w-6xl mx-auto px-4 py-2 flex items-center gap-6 relative">
        <div className="flex items-center gap-2 flex-shrink-0">
          <span className="text-xs uppercase tracking-wider text-brand-cyan">
            Bidding closes in
          </span>
          <span className="font-mono font-bold text-base text-white tabular-nums">
            {data ? fmtHMS(remaining) : "—:—:—"}
          </span>
        </div>

        <div className="text-brand-cyan/40 select-none">|</div>

        <div className="flex items-center gap-2 flex-1 min-w-0 overflow-hidden">
          <span className="text-xs uppercase tracking-wider text-brand-cyan flex-shrink-0">
            Latest signings
          </span>
          {transfers.length === 0 ? (
            <span className="italic text-white/60">no transfers yet</span>
          ) : (
            <div className="overflow-hidden flex-1">
              <div className="ticker-track">
                {doubled.map((t, i) => (
                  <span key={i} className="flex items-center gap-2 flex-shrink-0">
                    <span className="font-bold">{t.player}</span>
                    <span className="text-brand-cyan">→</span>
                    <span className="text-white/90">{t.team}</span>
                    <span className="text-brand-cyan/80 font-mono text-xs">
                      £{t.amount.toFixed(1)}m
                    </span>
                    <span className="text-brand-cyan/30 select-none">·</span>
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
