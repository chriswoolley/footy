import { Link } from "react-router-dom";
import { BrandBgLayers } from "../components/BrandBgLayers";
import { StandingsTable } from "../components/StandingsTable";

/**
 * Public guest view — reachable without logging in (route sits outside
 * <RequireAuth> in App.tsx). Shows ONLY the standings table; no squad, market,
 * bidding or admin. Reads the public /api/standings endpoint.
 */
export default function Guest() {
  return (
    <div className="brand-bg min-h-screen relative">
      <BrandBgLayers />
      <div className="relative max-w-3xl mx-auto px-4 py-10">
        <div className="text-center mb-6">
          <div className="flex items-baseline justify-center gap-1 font-bold text-3xl tracking-wider text-white">
            <span>DREAM</span>
            <span className="text-brand-cyan">TEAM</span>
          </div>
          <p className="text-xs text-white/70 mt-1 uppercase tracking-widest">
            Guest view — league standings
          </p>
        </div>

        <StandingsTable />

        <div className="mt-6 flex items-center justify-center gap-4 text-sm">
          <Link
            to="/login"
            className="inline-block bg-brand-cyan text-white px-5 py-2 rounded font-medium hover:bg-brand-cyanDark transition-colors"
          >
            Log in / Register to play
          </Link>
          <Link to="/how-it-works" className="text-white/80 hover:text-white underline">
            How it works
          </Link>
        </div>
        <p className="text-center text-white/50 text-xs mt-4">
          Guests can view the table only. Sign in to manage a squad and bid.
        </p>
      </div>
    </div>
  );
}
