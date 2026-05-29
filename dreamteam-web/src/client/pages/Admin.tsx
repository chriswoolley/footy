import { useEffect, useMemo, useState } from "react";
import { api } from "../api";
import { useSorted, sortableHeaderProps } from "../hooks/useSorted";

type Status = {
  mode: "immediate" | "deferred";
  lastBootstrapSync: string | null;
  lastLiveSync: string | null;
  lastLiveGw: string | null;
  counts: { managers: number; players: number; snapshots: number; pendingBids: number };
};

type PendingBid = {
  id: number;
  managerId: number;
  managerTeam: string;
  playerId: number;
  playerName: string;
  playerTeam: string;
  playerTeamShort: string;
  position: number;
  amount: number;
  placedAt: string;
};

type ManagerRow = {
  id: number;
  username: string;
  teamName: string;
  formation: string;
  createdAt: string;
  squadCount: number;
  bidCount: number;
};

type AuditRow = {
  id: number;
  who: string;
  what: string;
  when: string;
};

type TransferRow = {
  id: number;
  managerId: number;
  managerTeam: string;
  playerId: number;
  playerName: string;
  playerTeamShort: string;
  position: number;
  boughtAt: string;
  bidPrice: number;
  soldAt: string | null;
  sellPrice: number | null;
  status: "active" | "sold";
};

type BidLogRow = {
  id: number;
  managerId: number;
  managerTeam: string;
  playerId: number;
  playerName: string;
  playerTeamShort: string;
  position: number;
  amount: number;
  placedAt: string;
  status: "pending" | "won" | "lost";
};

const POS_NAME = { 1: "GK", 2: "DEF", 3: "MID", 4: "FWD" } as const;

export default function Admin() {
  const [status, setStatus] = useState<Status | null>(null);
  const [pending, setPending] = useState<PendingBid[]>([]);
  const [managers, setManagers] = useState<ManagerRow[]>([]);
  const [audits, setAudits] = useState<AuditRow[]>([]);
  const [transfers, setTransfers] = useState<TransferRow[]>([]);
  const [bidLog, setBidLog] = useState<BidLogRow[]>([]);
  const [busy, setBusy] = useState<string | null>(null);
  const [message, setMessage] = useState<{ kind: "ok" | "err"; text: string } | null>(null);

  async function refresh() {
    const [s, p, m, a, t, bl] = await Promise.all([
      api.get<Status>("/api/admin/status"),
      api.get<PendingBid[]>("/api/admin/pending-bids"),
      api.get<ManagerRow[]>("/api/admin/managers"),
      api.get<AuditRow[]>("/api/admin/audit"),
      api.get<TransferRow[]>("/api/admin/transfers"),
      api.get<BidLogRow[]>("/api/admin/bid-log"),
    ]);
    setStatus(s);
    setPending(p);
    setManagers(m);
    setAudits(a);
    setTransfers(t);
    setBidLog(bl);
  }

  useEffect(() => {
    refresh();
  }, []);

  async function run(label: string, fn: () => Promise<unknown>, confirmMsg?: string) {
    if (confirmMsg && !confirm(confirmMsg)) return;
    setBusy(label);
    setMessage(null);
    try {
      const out = await fn();
      setMessage({ kind: "ok", text: `${label}: ${JSON.stringify(out)}` });
      await refresh();
    } catch (e: any) {
      setMessage({ kind: "err", text: `${label}: ${e.message}` });
    } finally {
      setBusy(null);
    }
  }

  async function deleteManager(m: ManagerRow) {
    await run(
      `delete ${m.teamName}`,
      () => api.del(`/api/admin/managers/${m.id}`),
      `Permanently delete ${m.teamName} (${m.username}) and all their bids, squad and paper talk?`,
    );
  }

  // === sortable column configs (one per table) ===
  const pendingCols = useMemo(
    () => ({
      managerTeam: (r: PendingBid) => r.managerTeam,
      playerName: (r: PendingBid) => r.playerName,
      playerTeamShort: (r: PendingBid) => r.playerTeamShort,
      position: (r: PendingBid) => r.position,
      amount: (r: PendingBid) => r.amount,
      placedAt: (r: PendingBid) => new Date(r.placedAt),
    }),
    [],
  );
  const pendingSorted = useSorted(pending, pendingCols);

  const managersCols = useMemo(
    () => ({
      id: (r: ManagerRow) => r.id,
      username: (r: ManagerRow) => r.username,
      teamName: (r: ManagerRow) => r.teamName,
      formation: (r: ManagerRow) => r.formation,
      squadCount: (r: ManagerRow) => r.squadCount,
      bidCount: (r: ManagerRow) => r.bidCount,
      createdAt: (r: ManagerRow) => new Date(r.createdAt),
    }),
    [],
  );
  const managersSorted = useSorted(managers, managersCols);

  const transfersCols = useMemo(
    () => ({
      managerTeam: (r: TransferRow) => r.managerTeam,
      playerName: (r: TransferRow) => r.playerName,
      playerTeamShort: (r: TransferRow) => r.playerTeamShort,
      position: (r: TransferRow) => r.position,
      boughtAt: (r: TransferRow) => new Date(r.boughtAt),
      bidPrice: (r: TransferRow) => r.bidPrice,
      soldAt: (r: TransferRow) => (r.soldAt ? new Date(r.soldAt) : null),
      sellPrice: (r: TransferRow) => r.sellPrice,
      status: (r: TransferRow) => r.status,
    }),
    [],
  );
  const transfersSorted = useSorted(transfers, transfersCols, {
    key: "boughtAt",
    dir: "desc",
  });

  const bidLogCols = useMemo(
    () => ({
      managerTeam: (r: BidLogRow) => r.managerTeam,
      playerName: (r: BidLogRow) => r.playerName,
      playerTeamShort: (r: BidLogRow) => r.playerTeamShort,
      position: (r: BidLogRow) => r.position,
      amount: (r: BidLogRow) => r.amount,
      placedAt: (r: BidLogRow) => new Date(r.placedAt),
      status: (r: BidLogRow) => r.status,
    }),
    [],
  );
  const bidLogSorted = useSorted(bidLog, bidLogCols, { key: "placedAt", dir: "desc" });

  if (!status) return <div>Loading…</div>;

  const ts = (s: string | null) => (s ? new Date(s).toLocaleString() : "never");

  return (
    <div className="space-y-6">
      <h2 className="text-lg font-bold">Management Console</h2>
      {message && (
        <div
          className={`p-3 rounded text-sm ${
            message.kind === "ok" ? "bg-green-50 text-green-800" : "bg-red-50 text-red-800"
          }`}
        >
          {message.text}
        </div>
      )}

      {/* === League state === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">League state</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
          <StatBox label="Managers" value={status.counts.managers} />
          <StatBox label="Players cached" value={status.counts.players} />
          <StatBox label="Point snapshots" value={status.counts.snapshots} />
          <StatBox label="Pending bids" value={status.counts.pendingBids} highlight />
        </div>
        <div className="mt-4 text-sm text-slate-600 space-y-1">
          <div>Bootstrap last synced: <strong>{ts(status.lastBootstrapSync)}</strong></div>
          <div>
            Live last synced: <strong>{ts(status.lastLiveSync)}</strong>
            {status.lastLiveGw && (
              <span className="text-slate-500"> (GW{status.lastLiveGw})</span>
            )}
          </div>
        </div>
      </section>

      {/* === Bid mode === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-2">Bid mode</h3>
        <p className="text-sm text-slate-600 mb-3">
          {status.mode === "immediate" ? (
            <>
              <strong>Immediate</strong> — bids are accepted on the spot, no auction. Each player
              can be owned by only one manager.
            </>
          ) : (
            <>
              <strong>Deferred</strong> — bids stack as pending. Multiple managers can bid for the
              same player; the highest amount wins when you press <em>Run bids</em>.
            </>
          )}
        </p>
        <div className="flex gap-2">
          <button
            disabled={busy !== null || status.mode === "immediate"}
            onClick={() =>
              run("set mode immediate", () =>
                api.post("/api/admin/mode", { mode: "immediate" }),
              )
            }
            className={`px-3 py-1 rounded text-sm border ${
              status.mode === "immediate"
                ? "bg-slate-900 text-white border-slate-900"
                : "bg-white text-slate-700 border-slate-300 hover:bg-slate-100"
            }`}
          >
            Immediate
          </button>
          <button
            disabled={busy !== null || status.mode === "deferred"}
            onClick={() =>
              run("set mode deferred", () =>
                api.post("/api/admin/mode", { mode: "deferred" }),
              )
            }
            className={`px-3 py-1 rounded text-sm border ${
              status.mode === "deferred"
                ? "bg-slate-900 text-white border-slate-900"
                : "bg-white text-slate-700 border-slate-300 hover:bg-slate-100"
            }`}
          >
            Deferred (auction)
          </button>
        </div>
      </section>

      {/* === Pending bids === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-bold">Pending bids ({pending.length})</h3>
          <div className="flex gap-2">
            <button
              disabled={busy !== null || pending.length === 0}
              onClick={() => run("run bids", () => api.post("/api/admin/run-bids"))}
              className="px-3 py-1 bg-brand-cyan text-white rounded text-sm font-medium hover:bg-brand-cyanDark disabled:bg-slate-300 transition-colors"
            >
              Run bids
            </button>
            <button
              disabled={busy !== null || pending.length === 0}
              onClick={() =>
                run(
                  "clear pending bids",
                  () => api.post("/api/admin/clear-bids"),
                  `Cancel all ${pending.length} pending bids?`,
                )
              }
              className="px-3 py-1 text-sm border border-red-300 text-red-700 rounded hover:bg-red-50 disabled:opacity-50"
            >
              Cancel all
            </button>
          </div>
        </div>
        {pending.length === 0 ? (
          <p className="text-sm text-slate-500">No pending bids.</p>
        ) : (
          <table className="w-full text-sm">
            <thead className="text-xs uppercase text-slate-500 border-b border-slate-200">
              <tr>
                <th {...sortableHeaderProps(pendingSorted.toggle, "managerTeam", "text-left p-1")}>
                  Bidder{pendingSorted.indicator("managerTeam")}
                </th>
                <th {...sortableHeaderProps(pendingSorted.toggle, "playerName", "text-left p-1")}>
                  Player{pendingSorted.indicator("playerName")}
                </th>
                <th {...sortableHeaderProps(pendingSorted.toggle, "playerTeamShort", "text-left p-1")}>
                  Team{pendingSorted.indicator("playerTeamShort")}
                </th>
                <th {...sortableHeaderProps(pendingSorted.toggle, "position", "text-left p-1")}>
                  Pos{pendingSorted.indicator("position")}
                </th>
                <th {...sortableHeaderProps(pendingSorted.toggle, "amount", "text-right p-1")}>
                  Amount{pendingSorted.indicator("amount")}
                </th>
                <th {...sortableHeaderProps(pendingSorted.toggle, "placedAt", "text-left p-1")}>
                  Placed{pendingSorted.indicator("placedAt")}
                </th>
              </tr>
            </thead>
            <tbody>
              {pendingSorted.sorted.map((b) => (
                <tr key={b.id} className="border-t border-slate-100">
                  <td className="p-1">{b.managerTeam}</td>
                  <td className="p-1 font-medium">{b.playerName}</td>
                  <td className="p-1">{b.playerTeamShort}</td>
                  <td className="p-1">{POS_NAME[b.position as 1 | 2 | 3 | 4]}</td>
                  <td className="p-1 text-right">£{b.amount.toFixed(1)}m</td>
                  <td className="p-1 text-xs text-slate-500">
                    {new Date(b.placedAt).toLocaleString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {/* === Data actions === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">Data actions</h3>
        <div className="flex flex-wrap gap-2">
          <button
            disabled={busy !== null}
            onClick={() => run("WC sync", () => api.post("/api/admin/sync"))}
            className="px-3 py-1 text-sm border border-slate-300 rounded hover:bg-slate-100 disabled:opacity-50"
          >
            {busy === "WC sync" ? "Syncing…" : "Sync World Cup data"}
          </button>
          <button
            disabled={busy !== null}
            onClick={() =>
              run(
                "reseed",
                () => api.post("/api/admin/reseed"),
                "Reseed demo data? This wipes ALL squads, bids and paper talk entries (managers themselves are preserved). May take a minute.",
              )
            }
            className="px-3 py-1 text-sm border border-orange-300 text-orange-700 rounded hover:bg-orange-50 disabled:opacity-50"
          >
            {busy === "reseed" ? "Seeding…" : "Re-seed demo data"}
          </button>
        </div>
        <p className="mt-2 text-xs text-slate-500">
          Background scheduler still runs hourly + 5-min live regardless of these.
        </p>
      </section>

      {/* === Managers === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">Managers ({managers.length})</h3>
        <table className="w-full text-sm">
          <thead className="text-xs uppercase text-slate-500 border-b border-slate-200">
            <tr>
              <th {...sortableHeaderProps(managersSorted.toggle, "id", "text-left p-1")}>
                #{managersSorted.indicator("id")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "username", "text-left p-1")}>
                Username{managersSorted.indicator("username")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "teamName", "text-left p-1")}>
                Team{managersSorted.indicator("teamName")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "formation", "text-left p-1")}>
                Form.{managersSorted.indicator("formation")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "squadCount", "text-right p-1")}>
                Squad{managersSorted.indicator("squadCount")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "bidCount", "text-right p-1")}>
                Bids{managersSorted.indicator("bidCount")}
              </th>
              <th {...sortableHeaderProps(managersSorted.toggle, "createdAt", "text-left p-1")}>
                Joined{managersSorted.indicator("createdAt")}
              </th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {managersSorted.sorted.map((m) => (
              <tr key={m.id} className="border-t border-slate-100">
                <td className="p-1">{m.id}</td>
                <td className="p-1">{m.username}</td>
                <td className="p-1 font-medium">{m.teamName}</td>
                <td className="p-1">{m.formation}</td>
                <td className="p-1 text-right">{m.squadCount}</td>
                <td className="p-1 text-right">{m.bidCount}</td>
                <td className="p-1 text-xs text-slate-500">
                  {new Date(m.createdAt).toLocaleDateString()}
                </td>
                <td className="p-1 text-right">
                  <button
                    onClick={() => deleteManager(m)}
                    disabled={busy !== null}
                    className="text-xs text-red-600 hover:underline disabled:opacity-50"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      {/* === Transfer log === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">Transfer log ({transfers.length})</h3>
        {transfers.length === 0 ? (
          <p className="text-sm text-slate-500">No transfers yet.</p>
        ) : (
          <div className="overflow-x-auto max-h-96">
            <table className="w-full text-sm">
              <thead className="text-xs uppercase text-slate-500 border-b border-slate-200 sticky top-0 bg-white">
                <tr>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "managerTeam", "text-left p-1")}>
                    Manager{transfersSorted.indicator("managerTeam")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "playerName", "text-left p-1")}>
                    Player{transfersSorted.indicator("playerName")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "playerTeamShort", "text-left p-1")}>
                    Club{transfersSorted.indicator("playerTeamShort")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "position", "text-left p-1")}>
                    Pos{transfersSorted.indicator("position")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "boughtAt", "text-left p-1")}>
                    Bought{transfersSorted.indicator("boughtAt")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "bidPrice", "text-right p-1")}>
                    Bid £{transfersSorted.indicator("bidPrice")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "soldAt", "text-left p-1")}>
                    Sold{transfersSorted.indicator("soldAt")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "sellPrice", "text-right p-1")}>
                    Sell £{transfersSorted.indicator("sellPrice")}
                  </th>
                  <th {...sortableHeaderProps(transfersSorted.toggle, "status", "text-left p-1")}>
                    Status{transfersSorted.indicator("status")}
                  </th>
                </tr>
              </thead>
              <tbody>
                {transfersSorted.sorted.map((t) => {
                  const isLoss =
                    t.sellPrice != null && t.sellPrice < t.bidPrice - 1e-9;
                  return (
                  <tr
                    key={t.id}
                    className={`border-t border-slate-100 ${isLoss ? "bg-red-50" : ""}`}
                  >
                    <td className="p-1">{t.managerTeam}</td>
                    <td className="p-1 font-medium">{t.playerName}</td>
                    <td className="p-1">{t.playerTeamShort}</td>
                    <td className="p-1">{POS_NAME[t.position as 1 | 2 | 3 | 4]}</td>
                    <td className="p-1 text-xs text-slate-500">
                      {new Date(t.boughtAt).toLocaleDateString()}
                    </td>
                    <td className="p-1 text-right">£{t.bidPrice.toFixed(1)}m</td>
                    <td className="p-1 text-xs text-slate-500">
                      {t.soldAt ? new Date(t.soldAt).toLocaleDateString() : "—"}
                    </td>
                    <td className="p-1 text-right">
                      {t.sellPrice != null ? `£${t.sellPrice.toFixed(1)}m` : "—"}
                    </td>
                    <td className="p-1">
                      <span
                        className={`text-xs px-2 py-0.5 rounded ${
                          t.status === "active"
                            ? "bg-green-100 text-green-800"
                            : "bg-slate-200 text-slate-600"
                        }`}
                      >
                        {t.status}
                      </span>
                    </td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* === Bidding log === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">Bidding log ({bidLog.length})</h3>
        {bidLog.length === 0 ? (
          <p className="text-sm text-slate-500">No bids yet.</p>
        ) : (
          <div className="overflow-x-auto max-h-96">
            <table className="w-full text-sm">
              <thead className="text-xs uppercase text-slate-500 border-b border-slate-200 sticky top-0 bg-white">
                <tr>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "managerTeam", "text-left p-1")}>
                    Bidder{bidLogSorted.indicator("managerTeam")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "playerName", "text-left p-1")}>
                    Player{bidLogSorted.indicator("playerName")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "playerTeamShort", "text-left p-1")}>
                    Club{bidLogSorted.indicator("playerTeamShort")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "position", "text-left p-1")}>
                    Pos{bidLogSorted.indicator("position")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "amount", "text-right p-1")}>
                    Amount{bidLogSorted.indicator("amount")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "placedAt", "text-left p-1")}>
                    Placed{bidLogSorted.indicator("placedAt")}
                  </th>
                  <th {...sortableHeaderProps(bidLogSorted.toggle, "status", "text-left p-1")}>
                    Status{bidLogSorted.indicator("status")}
                  </th>
                </tr>
              </thead>
              <tbody>
                {bidLogSorted.sorted.map((b) => (
                  <tr
                    key={b.id}
                    className={`border-t border-slate-100 ${b.status === "lost" ? "bg-red-50" : ""}`}
                  >
                    <td className="p-1">{b.managerTeam}</td>
                    <td className="p-1 font-medium">{b.playerName}</td>
                    <td className="p-1">{b.playerTeamShort}</td>
                    <td className="p-1">{POS_NAME[b.position as 1 | 2 | 3 | 4]}</td>
                    <td className="p-1 text-right">£{b.amount.toFixed(1)}m</td>
                    <td className="p-1 text-xs text-slate-500">
                      {new Date(b.placedAt).toLocaleString()}
                    </td>
                    <td className="p-1">
                      <span
                        className={`text-xs px-2 py-0.5 rounded ${
                          b.status === "won"
                            ? "bg-green-100 text-green-800"
                            : b.status === "lost"
                              ? "bg-red-100 text-red-700"
                              : "bg-amber-100 text-amber-800"
                        }`}
                      >
                        {b.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* === Audit log === */}
      <section className="bg-white rounded shadow border border-slate-200 p-4">
        <h3 className="font-bold mb-3">Audit log (last 100)</h3>
        {audits.length === 0 ? (
          <p className="text-sm text-slate-500">No audit entries yet.</p>
        ) : (
          <ul className="text-sm space-y-1 font-mono">
            {audits.map((a) => (
              <li key={a.id} className="flex gap-2">
                <span className="text-slate-400 whitespace-nowrap">
                  {new Date(a.when).toLocaleString()}
                </span>
                <span className="text-slate-500">{a.who}</span>
                <span>{a.what}</span>
              </li>
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function StatBox({
  label,
  value,
  highlight,
}: {
  label: string;
  value: number | string;
  highlight?: boolean;
}) {
  return (
    <div
      className={`rounded p-3 border ${
        highlight ? "border-amber-200 bg-amber-50" : "border-slate-100 bg-slate-50"
      }`}
    >
      <div className="text-xs uppercase text-slate-500">{label}</div>
      <div className="text-2xl font-bold">{value}</div>
    </div>
  );
}
