import type { SquadEntryDTO } from "../api";
import { PlayerHistoryPopup } from "./PlayerHistoryPopup";

const POSITION_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

const LAYOUTS: Record<"442" | "433", { rows: number[]; slotPositions: number[] }> = {
  "442": {
    rows: [1, 4, 4, 2],
    slotPositions: [1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4],
  },
  "433": {
    rows: [1, 4, 3, 3],
    slotPositions: [1, 2, 2, 2, 2, 3, 3, 3, 4, 4, 4],
  },
};

type Props = {
  formation: "442" | "433";
  entries: SquadEntryDTO[];
  onDropOnSlot: (playerId: number, slot: number) => void;
  onBench: (playerId: number) => void;
};

// Six alternating stripes give the pitch the classic mown-grass feel from the
// FPL Pitch View; lighter top, darker bottom for a subtle depth cue.
const STRIPE_COLORS = ["#2b8a4b", "#247a40", "#2b8a4b", "#247a40", "#2b8a4b", "#247a40"];

export function Pitch({ formation, entries, onDropOnSlot, onBench }: Props) {
  const { rows, slotPositions } = LAYOUTS[formation];
  const slotEntry = (slot: number) =>
    entries.find((e) => e.playing && e.formationSlot === slot) ?? null;

  let slotCounter = 0;
  const rowSlots = rows.map((count) => {
    const slots: number[] = [];
    for (let i = 0; i < count; i++) slots.push(slotCounter++);
    return slots;
  });

  return (
    <div className="mx-auto max-w-md" style={{ perspective: "900px" }}>
    <div
      className="relative shadow-lg border border-emerald-900/50 aspect-[3/4]"
      style={{
        // 20° forward tilt — back of the pitch recedes; preserve-3d lets the
        // player labels counter-rotate so they stay upright on the tilted floor.
        transformOrigin: "center bottom",
        transform: "rotateX(30deg)",
        transformStyle: "preserve-3d",
        borderRadius: "0.5rem",
      }}
    >
      {/* Grass stripes */}
      <div className="absolute inset-0 flex flex-col">
        {STRIPE_COLORS.map((c, i) => (
          <div key={i} className="flex-1" style={{ background: c }} />
        ))}
      </div>

      {/* Pitch markings */}
      <svg
        className="absolute inset-0 w-full h-full pointer-events-none"
        viewBox="0 0 300 400"
        preserveAspectRatio="none"
      >
        {/* Outer touchline */}
        <rect
          x="6"
          y="6"
          width="288"
          height="388"
          fill="none"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        {/* Top penalty area */}
        <rect
          x="60"
          y="6"
          width="180"
          height="60"
          fill="none"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        {/* Top six-yard box */}
        <rect
          x="105"
          y="6"
          width="90"
          height="26"
          fill="none"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        {/* Top penalty spot */}
        <circle cx="150" cy="50" r="2" fill="rgba(255,255,255,0.85)" />
        {/* Top penalty D — arc protruding into the pitch from the penalty area */}
        <path
          d="M 130 66 A 22 22 0 0 0 170 66"
          fill="none"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        {/* Halfway line */}
        <line
          x1="6"
          y1="200"
          x2="294"
          y2="200"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        {/* Center circle + spot */}
        <circle
          cx="150"
          cy="200"
          r="36"
          fill="none"
          stroke="rgba(255,255,255,0.85)"
          strokeWidth="2"
        />
        <circle cx="150" cy="200" r="2" fill="rgba(255,255,255,0.85)" />
      </svg>

      {/* Goal mouth at top — net mesh */}
      <div className="absolute left-1/2 -translate-x-1/2 top-[6px] w-[110px] h-[14px] flex items-center justify-center">
        <div
          className="w-full h-full rounded-sm"
          style={{
            backgroundImage:
              "linear-gradient(rgba(255,255,255,0.7) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.7) 1px, transparent 1px)",
            backgroundSize: "8px 5px",
            border: "1px solid rgba(255,255,255,0.9)",
            background:
              "repeating-linear-gradient(90deg, rgba(255,255,255,0.5) 0 1px, transparent 1px 5px), repeating-linear-gradient(0deg, rgba(255,255,255,0.5) 0 1px, transparent 1px 4px), rgba(255,255,255,0.08)",
          }}
        />
      </div>

      {/* Players — counter-rotate so the cards stay readable on the tilted pitch */}
      <div
        className="absolute inset-0 p-4 pt-10 flex flex-col-reverse justify-around"
        style={{ transformStyle: "preserve-3d" }}
      >
        {rowSlots.map((slots, rowIdx) => (
          <div
            key={rowIdx}
            className="flex justify-around items-center"
            style={{ transformStyle: "preserve-3d" }}
          >
            {slots.map((slot) => {
              const entry = slotEntry(slot);
              const required = slotPositions[slot];
              return (
                <div
                  key={slot}
                  onDragOver={(e) => {
                    e.preventDefault();
                  }}
                  onDrop={(e) => {
                    e.preventDefault();
                    const playerId = Number(e.dataTransfer.getData("text/plain"));
                    if (!Number.isNaN(playerId)) onDropOnSlot(playerId, slot);
                  }}
                  className="flex flex-col items-center w-16 group"
                  style={{ transform: "rotateX(-30deg)", transformOrigin: "center bottom" }}
                >
                  {entry ? (
                    <PlayerHistoryPopup playerId={entry.playerId}>
                      <button
                        draggable
                        onDragStart={(e) =>
                          e.dataTransfer.setData("text/plain", String(entry.playerId))
                        }
                        onDoubleClick={() => onBench(entry.playerId)}
                        title={`${entry.name} (${entry.teamShort}) — double-click to bench`}
                        className="w-12 h-12 rounded-full bg-white overflow-hidden shadow-md ring-1 ring-white/80 group-hover:scale-110 transition-transform"
                      >
                        {entry.photoUrl ? (
                          <img
                            src={entry.photoUrl}
                            alt={entry.name}
                            loading="lazy"
                            onError={(e) => {
                              (e.currentTarget as HTMLImageElement).style.display = "none";
                              const fallback = e.currentTarget
                                .nextElementSibling as HTMLElement | null;
                              if (fallback) fallback.style.display = "flex";
                            }}
                            className="w-full h-full object-cover object-top"
                          />
                        ) : null}
                        <span
                          className="w-full h-full text-emerald-900 text-xs font-bold items-center justify-center"
                          style={{ display: entry.photoUrl ? "none" : "flex" }}
                        >
                          {entry.teamShort}
                        </span>
                      </button>
                      {/* Name plate — FPL-style dark badge */}
                      <div className="mt-1 max-w-[68px] w-[68px] truncate text-center text-[10px] font-semibold text-white bg-emerald-950 rounded px-1 py-[1px] shadow">
                        {entry.name}
                      </div>
                      {/* Team plate */}
                      <div className="max-w-[68px] w-[68px] truncate text-center text-[9px] font-bold text-emerald-900 bg-emerald-100 rounded px-1 py-[1px] mt-[1px]">
                        {entry.teamShort}
                      </div>
                      {/* Price line: paid (bid) vs current book */}
                      <div
                        className="max-w-[68px] w-[68px] text-center text-[8.5px] mt-[1px] leading-tight"
                        title={`Paid £${entry.bid.toFixed(1)}m, current book £${entry.price.toFixed(1)}m`}
                      >
                        <span className="text-amber-300 font-semibold">£{entry.bid.toFixed(1)}</span>
                        <span className="text-white/70 mx-[2px]">/</span>
                        <span className="text-white/90">£{entry.price.toFixed(1)}</span>
                      </div>
                    </PlayerHistoryPopup>
                  ) : (
                    <>
                      <div className="w-12 h-12 rounded-full border-2 border-dashed border-white/60 text-white/80 text-[10px] flex items-center justify-center">
                        {POSITION_NAME[required as 1 | 2 | 3 | 4]}
                      </div>
                      <div className="mt-1 text-[10px] text-white/70">empty</div>
                    </>
                  )}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
    </div>
  );
}
