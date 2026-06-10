import { Routes, Route, Navigate } from "react-router-dom";
import Layout from "./components/Layout";
import Login from "./pages/Login";
import Squad from "./pages/Squad";
import Market from "./pages/Market";
import Standings from "./pages/Standings";
import Points from "./pages/Points";
import PaperTalk from "./pages/PaperTalk";
import Graphs from "./pages/Graphs";
import Admin from "./pages/Admin";
import Fixtures from "./pages/Fixtures";
import HowItWorks from "./pages/HowItWorks";
import Guest from "./pages/Guest";
import { useAuth } from "./auth";

function RequireAuth({ children }: { children: JSX.Element }) {
  const { me, loading } = useAuth();
  if (loading) return <div className="p-8 text-slate-500">Loading…</div>;
  if (!me) return <Navigate to="/login" replace />;
  return children;
}

function RequireAdmin({ children }: { children: JSX.Element }) {
  const { me } = useAuth();
  if (!me?.isAdmin) return <Navigate to="/squad" replace />;
  return children;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/how-it-works" element={<HowItWorks />} />
      <Route path="/guest" element={<Guest />} />
      <Route
        element={
          <RequireAuth>
            <Layout />
          </RequireAuth>
        }
      >
        <Route index element={<Navigate to="/squad" replace />} />
        <Route path="/squad" element={<Squad />} />
        <Route path="/market" element={<Market />} />
        <Route path="/standings" element={<Standings />} />
        <Route path="/points" element={<Points />} />
        <Route path="/paper-talk" element={<PaperTalk />} />
        <Route path="/graphs" element={<Graphs />} />
        <Route path="/fixtures" element={<Fixtures />} />
        <Route
          path="/admin"
          element={
            <RequireAdmin>
              <Admin />
            </RequireAdmin>
          }
        />
      </Route>
    </Routes>
  );
}
