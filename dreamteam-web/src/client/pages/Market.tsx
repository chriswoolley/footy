import { useEffect, useMemo, useState } from "react";
import { api, type Player, type Squad } from "../api";

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

export default function Market() {
  const [players, setPlayers] = useState<Player[]>([]);
  const [position, setPosition] = useState<number | "">("");
  const [maxPrice, setMaxPrice] = useState("");
  const [q, setQ] = useState("");
  const [bidding, setBidding] = useState<Player | null>(null);
  const [bidAmount, setBidAmount] = useState("");
  const [squad, setSquad] = useState<Squad | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function load() {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (position) params.set("position", String(position));
      if (maxPrice) params.set("maxPrice", maxPrice);
      if (q) params.set("q", q);
      const [list, s] = await Promise.all([
        api.get<Player[]>(`/api/players?${params.toString()}`),
        api.get<Squad>("/api/squad"),
      ]);
      setPlayers(list);
      setSquad(s);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [position, maxPrice, q]);

  const ownedIds = useMemo(
    () => new Set(squad?.entries.map((e) => e.playerId) ?? []),
    [squad],
  );

  async function placeBid() {
    if (!bidding) return;
    setErr(null);
    try {
      await api.post("/api/bids", {
        playerId: bidding.id,
        amount: Number(bidAmount || bidding.price),
      });
      setBidding(null);
      setBidAmount("");
      load();
    } catch (e: any) {
      setErr(e.message);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-bold mb-3">Transfer Market</h2>
      {squad && (
        <div className="mb-3 flex items-center justify-between flex-wrap gap-2">
          <div className="text-sm text-slate-600">
            Balance: <strong>£{squad.balance.toFixed(1)}m</strong> · Spent: £
            {squad.spent.toFixed(1)}m
          </div>
          <div className="text-xs px-2 py-1 rounded bg-amber-100 text-amber-800 border border-amber-200">
            Sealed-bid auction
          </div>
        </div>
      )}
      <div className="flex gap-2 mb-3 flex-wrap">
        <select
          className="border rounded px-2 py-1 text-sm"
          value={position}
          onChange={(e) => setPosition(e.target.value ? Number(e.target.value) : "")}
        >
          <option value="">All positions</option>
          <option value={1}>Goalkeepers</option>
          <option value={2}>Defenders</option>
          <option value={3}>Midfielders</option>
          <option value={4}>Forwards</option>
        </select>
        <input
          className="border rounded px-2 py-1 text-sm"
          placeholder="Max price (e.g. 7.5)"
          value={maxPrice}
          onChange={(e) => setMaxPrice(e.target.value)}
          inputMode="decimal"
        />
        <input
          className="border rounded px-2 py-1 text-sm flex-1 min-w-[200px]"
          placeholder="Search name…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
        <button onClick={load} className="text-sm border px-3 rounded hover:bg-slate-100">
          {loading ? "…" : "Refresh"}
        </button>
      </div>

      <div className="overflow-auto bg-white rounded shadow border border-slate-200">
        <table className="w-full text-sm">
          <thead className="bg-slate-100 text-xs uppercase text-slate-600">
            <tr>
              <th className="text-left p-2">Pos</th>
              <th className="text-left p-2">Player</th>
              <th className="text-left p-2">Team</th>
              <th className="text-right p-2">Price</th>
              <th className="text-right p-2">Points</th>
              <th className="text-right p-2">Form</th>
              <th className="text-left p-2">Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {players.map((p) => (
              <tr key={p.id} className="border-t border-slate-100 hover:bg-slate-50">
                <td className="p-2">{POS_NAME[p.position]}</td>
                <td className="p-2 font-medium">
                  <div className="flex items-center gap-2">
                    {p.photoUrl ? (
                      <img
                        src={p.photoUrl}
                        alt=""
                        loading="lazy"
                        className="w-7 h-7 rounded-full object-cover object-top bg-slate-100"
                        onError={(e) => {
                          (e.currentTarget as HTMLImageElement).style.visibility = "hidden";
                        }}
                      />
                    ) : (
                      <div className="w-7 h-7 rounded-full bg-slate-200" />
                    )}
                    <span>{p.name}</span>
                  </div>
                </td>
                <td className="p-2">{p.teamShort}</td>
                <td className="p-2 text-right">£{p.price.toFixed(1)}m</td>
                <td className="p-2 text-right">{p.points}</td>
                <td className="p-2 text-right">{p.form.toFixed(1)}</td>
                <td className="p-2 text-slate-500 text-xs">
                  {p.status === "a"
                    ? ""
                    : p.status === "i"
                      ? "Injured"
                      : p.status === "d"
                        ? "Doubt"
                        : p.status === "s"
                          ? "Suspended"
                          : p.status}
                </td>
                <td className="p-2 text-right">
                  {ownedIds.has(p.id) ? (
                    <span className="text-xs text-slate-400">Mine</span>
                  ) : p.ownedBy ? (
                    <span
                      className="text-xs text-slate-400"
                      title={`Owned by ${p.ownedBy.teamName}`}
                    >
                      {p.ownedBy.teamName}
                    </span>
                  ) : (
                    <button
                      onClick={() => {
                        setBidding(p);
                        setBidAmount(p.price.toFixed(1));
                      }}
                      className="text-xs px-2 py-1 bg-brand-cyan text-white rounded hover:bg-brand-cyanDark transition-colors"
                    >
                      Bid
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {bidding && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center"
          onClick={() => setBidding(null)}
        >
          <div
            className="bg-white rounded p-6 w-full max-w-sm space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3">
              {bidding.photoUrl && (
                <img
                  src={bidding.photoUrl}
                  alt=""
                  className="w-16 h-16 rounded-full object-cover object-top bg-slate-100"
                />
              )}
              <div>
                <h3 className="font-bold">
                  Bid for {bidding.name}{" "}
                  <span className="text-slate-400">({bidding.teamShort})</span>
                </h3>
                <p className="text-sm text-slate-600">
                  List price £{bidding.price.toFixed(1)}m · Points {bidding.points}
                </p>
              </div>
            </div>
            <div className="text-xs bg-amber-50 border border-amber-200 text-amber-800 rounded p-2">
              Sealed-bid auction — your bid is pending until the next bid run. Higher bids from other
              managers will outbid you.
            </div>
            <input
              autoFocus
              className="w-full border rounded px-3 py-2"
              value={bidAmount}
              onChange={(e) => setBidAmount(e.target.value)}
              placeholder="Bid amount (£m)"
              inputMode="decimal"
            />
            {err && <div className="text-red-600 text-sm">{err}</div>}
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => setBidding(null)}
                className="px-3 py-1 border rounded"
              >
                Cancel
              </button>
              <button
                onClick={placeBid}
                className="px-3 py-1 bg-brand-cyan text-white rounded hover:bg-brand-cyanDark transition-colors"
              >
                Place pending bid
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
