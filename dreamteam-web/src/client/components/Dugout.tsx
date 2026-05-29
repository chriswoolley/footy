import type { SquadEntryDTO } from "../api";
import { PlayerHistoryPopup } from "./PlayerHistoryPopup";

type Props = {
  bench: SquadEntryDTO[];
  onBench: (playerId: number) => void;
};

const POSITION_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

// Vertical bench panel: shows every owned-but-not-playing player. Drag a card
// onto a pitch slot to sub them on; drag a pitch player here to bench them.
export function Dugout({ bench, onBench }: Props) {
  return (
    <div className="h-full" style={{ perspective: "900px" }}>
    <div
      onDragOver={(e) => e.preventDefault()}
      onDrop={(e) => {
        e.preventDefault();
        const playerId = Number(e.dataTransfer.getData("text/plain"));
        if (!Number.isNaN(playerId)) onBench(playerId);
      }}
      className="relative shadow-md border border-amber-900/40 flex flex-col h-full"
      style={{
        // Share the pitch's 20° tilt with transform-origin: bottom so the
        // dugout's bottom edge sits on the same ground as the pitch.
        transformOrigin: "center bottom",
        transform: "rotateX(30deg)",
        transformStyle: "preserve-3d",
        borderRadius: "0.5rem",
        background:
          "linear-gradient(180deg, #5b3a1f 0%, #6e472a 8%, #8a5a37 12%, #c08a5a 100%)",
      }}
    >
      {/* Dugout roof / awning */}
      <div
        className="text-amber-50 text-center text-[11px] font-bold tracking-widest py-1 shadow-inner"
        style={{
          background: "linear-gradient(180deg, #2d1a0c 0%, #4a2b14 100%)",
        }}
      >
        DUGOUT
      </div>

      {/* Bench seating with planks effect */}
      <div
        className="flex-1 grid grid-cols-2 gap-1 p-2 pb-3"
        style={{
          backgroundImage:
            "repeating-linear-gradient(180deg, rgba(0,0,0,0.05) 0 14px, rgba(0,0,0,0.12) 14px 16px)",
          transformStyle: "preserve-3d",
        }}
      >
        {bench.length === 0 ? (
          <div className="col-span-2 text-center text-[10px] text-amber-50/70 mt-4 italic">
            no one on the bench
          </div>
        ) : (
          bench.map((e) => (
            <PlayerHistoryPopup key={e.id} playerId={e.playerId}>
            <div
              draggable
              onDragStart={(ev) => ev.dataTransfer.setData("text/plain", String(e.playerId))}
              title={`${e.name} (${POSITION_NAME[e.position]}, ${e.teamShort}) — drag onto a pitch slot to bring on`}
              className="flex flex-col items-center bg-amber-50/95 rounded shadow-sm cursor-grab active:cursor-grabbing hover:scale-105 transition-transform select-none"
              style={{ transform: "rotateX(-30deg)", transformOrigin: "center bottom" }}
            >
              <div className="w-10 h-10 rounded-full bg-white overflow-hidden border border-amber-900/30 mt-1 shadow-sm">
                {e.photoUrl ? (
                  <img
                    src={e.photoUrl}
                    alt={e.name}
                    loading="lazy"
                    onError={(ev) => {
                      (ev.currentTarget as HTMLImageElement).style.display = "none";
                      const fallback = ev.currentTarget.nextElementSibling as HTMLElement | null;
                      if (fallback) fallback.style.display = "flex";
                    }}
                    className="w-full h-full object-cover object-top"
                  />
                ) : null}
                <span
                  className="w-full h-full text-emerald-900 text-[10px] font-bold items-center justify-center"
                  style={{ display: e.photoUrl ? "none" : "flex" }}
                >
                  {e.teamShort}
                </span>
              </div>
              <div className="text-[9px] font-semibold leading-tight text-emerald-950 truncate w-full text-center px-1">
                {e.name}
              </div>
              <div className="text-[8px] font-bold leading-tight text-amber-900/80">
                {POSITION_NAME[e.position]} · {e.teamShort}
              </div>
              <div
                className="text-[8px] leading-tight mb-1"
                title={`Paid £${e.bid.toFixed(1)}m, current book £${e.price.toFixed(1)}m`}
              >
                <span className="font-semibold text-amber-900">£{e.bid.toFixed(1)}</span>
                <span className="text-amber-900/50 mx-[1px]">/</span>
                <span className="text-emerald-900">£{e.price.toFixed(1)}</span>
              </div>
            </div>
            </PlayerHistoryPopup>
          ))
        )}
      </div>
    </div>
    </div>
  );
}
