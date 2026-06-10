import { useState } from "react";
import { NavLink, Outlet, useNavigate } from "react-router-dom";
import { useAuth } from "../auth";
import { api } from "../api";
import { Ticker } from "./Ticker";
import { BrandBgLayers } from "./BrandBgLayers";
import { ScheduleNotice } from "./ScheduleNotice";

const link =
  "px-3 py-2 text-sm font-medium tracking-wide text-white/85 hover:text-white border-b-2 border-transparent hover:border-brand-cyan/60 transition-colors";
const active = "text-white border-brand-cyan";

export default function Layout() {
  const { me, logout, refresh } = useAuth();
  const nav = useNavigate();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState("");
  const [saving, setSaving] = useState(false);

  if (!me) return <Outlet />;

  async function saveName() {
    const next = name.trim();
    if (!next) return;
    setSaving(true);
    try {
      await api.post("/api/auth/team-name", { teamName: next });
      await refresh();
      setEditing(false);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <ScheduleNotice />
      <header className="brand-bg text-white shadow-md relative">
        <BrandBgLayers />
        <div className="brand-swoosh" aria-hidden />
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center gap-4 relative">
          <div className="flex items-baseline gap-1 font-bold text-lg tracking-wider">
            <span>DREAM</span>
            <span className="text-brand-cyan">TEAM</span>
          </div>
          <nav className="flex gap-1 flex-1 ml-4">
            <NavLink to="/squad" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
              Squad
            </NavLink>
            <NavLink to="/market" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
              Market
            </NavLink>
            <NavLink
              to="/standings"
              className={({ isActive }) => `${link} ${isActive ? active : ""}`}
            >
              Standings
            </NavLink>
            <NavLink to="/points" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
              Points
            </NavLink>
            <NavLink
              to="/paper-talk"
              className={({ isActive }) => `${link} ${isActive ? active : ""}`}
            >
              Paper Talk
            </NavLink>
            <NavLink to="/graphs" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
              Graphs
            </NavLink>
            <NavLink to="/fixtures" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
              Fixtures
            </NavLink>
            <NavLink
              to="/how-it-works"
              className={({ isActive }) => `${link} ${isActive ? active : ""}`}
            >
              Rules
            </NavLink>
            {me.isAdmin && (
              <NavLink to="/admin" className={({ isActive }) => `${link} ${isActive ? active : ""}`}>
                Admin
              </NavLink>
            )}
          </nav>
          <div className="text-sm flex items-center gap-2">
            {editing ? (
              <span className="flex items-center gap-1">
                <input
                  className="text-slate-800 rounded px-2 py-0.5 text-sm w-40"
                  value={name}
                  maxLength={60}
                  autoFocus
                  onChange={(e) => setName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") saveName();
                    if (e.key === "Escape") setEditing(false);
                  }}
                />
                <button
                  onClick={saveName}
                  disabled={saving}
                  className="text-xs px-2 py-0.5 rounded bg-brand-cyan text-white hover:bg-brand-cyanDark disabled:opacity-50"
                >
                  Save
                </button>
                <button
                  onClick={() => setEditing(false)}
                  className="text-xs px-1 text-white/70 hover:text-white"
                  title="Cancel"
                >
                  ✕
                </button>
              </span>
            ) : (
              <>
                <span className="font-semibold text-white">{me.teamName}</span>{" "}
                <span className="text-white/60">({me.username})</span>
                <button
                  onClick={() => {
                    setName(me.teamName);
                    setEditing(true);
                  }}
                  className="text-xs px-2 py-1 rounded border border-white/30 text-white/90 hover:bg-white/10 hover:border-brand-cyan transition-colors"
                >
                  Rename
                </button>
              </>
            )}
          </div>
          <button
            onClick={async () => {
              await logout();
              nav("/login");
            }}
            className="text-sm px-3 py-1 rounded border border-white/30 text-white/90 hover:bg-white/10 hover:border-brand-cyan transition-colors"
          >
            Logout
          </button>
        </div>
      </header>
      <main className="flex-1 max-w-6xl mx-auto w-full px-4 py-6 pb-16">
        <Outlet />
      </main>
      <footer className="sticky bottom-0 z-10">
        <Ticker />
      </footer>
    </div>
  );
}
