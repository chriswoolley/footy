import { useState } from "react";
import { useNavigate, Navigate } from "react-router-dom";
import { api, type Me } from "../api";
import { useAuth } from "../auth";
import { BrandBgLayers } from "../components/BrandBgLayers";

export default function Login() {
  const { me, refresh } = useAuth();
  const nav = useNavigate();
  const [mode, setMode] = useState<"login" | "register">("login");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [teamName, setTeamName] = useState("");
  const [email, setEmail] = useState("");
  const [err, setErr] = useState<string | null>(null);

  if (me) return <Navigate to="/squad" replace />;

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    try {
      if (mode === "login") {
        await api.post<Me>("/api/auth/login", { username, password });
      } else {
        await api.post<Me>("/api/auth/register", { username, password, teamName, email });
      }
      await refresh();
      nav("/squad");
    } catch (e: any) {
      setErr(e.message);
    }
  }

  return (
    <div className="brand-bg min-h-screen flex items-center justify-center px-4">
      <BrandBgLayers />
      <form
        onSubmit={submit}
        className="bg-white p-8 rounded-lg shadow-2xl w-full max-w-sm space-y-4 border-t-4 border-brand-cyan"
      >
        <div className="text-center">
          <div className="flex items-baseline justify-center gap-1 font-bold text-2xl tracking-wider text-brand-navy">
            <span>DREAM</span>
            <span className="text-brand-cyan">TEAM</span>
          </div>
          <p className="text-xs text-brand-grey/70 mt-1 uppercase tracking-widest">
            Fantasy Football Auction League
          </p>
        </div>
        <div className="flex gap-2 text-sm">
          <button
            type="button"
            onClick={() => setMode("login")}
            className={`flex-1 py-2 rounded font-medium transition-colors ${
              mode === "login"
                ? "bg-brand-navy text-white"
                : "bg-brand-lightGrey text-brand-grey hover:bg-slate-200"
            }`}
          >
            Login
          </button>
          <button
            type="button"
            onClick={() => setMode("register")}
            className={`flex-1 py-2 rounded font-medium transition-colors ${
              mode === "register"
                ? "bg-brand-navy text-white"
                : "bg-brand-lightGrey text-brand-grey hover:bg-slate-200"
            }`}
          >
            Register
          </button>
        </div>
        <input
          className="w-full border border-slate-300 rounded px-3 py-2 focus:outline-none focus:border-brand-cyan focus:ring-1 focus:ring-brand-cyan"
          placeholder="Username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
        />
        <input
          className="w-full border border-slate-300 rounded px-3 py-2 focus:outline-none focus:border-brand-cyan focus:ring-1 focus:ring-brand-cyan"
          placeholder="Password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        {mode === "register" && (
          <>
            <input
              className="w-full border border-slate-300 rounded px-3 py-2 focus:outline-none focus:border-brand-cyan focus:ring-1 focus:ring-brand-cyan"
              placeholder="Team name"
              value={teamName}
              onChange={(e) => setTeamName(e.target.value)}
            />
            <input
              className="w-full border border-slate-300 rounded px-3 py-2 focus:outline-none focus:border-brand-cyan focus:ring-1 focus:ring-brand-cyan"
              placeholder="Email (optional)"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </>
        )}
        {err && <div className="text-red-600 text-sm">{err}</div>}
        <button className="w-full bg-brand-cyan text-white py-2 rounded font-medium hover:bg-brand-cyanDark transition-colors">
          {mode === "login" ? "Login" : "Create account"}
        </button>
      </form>
    </div>
  );
}
