import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { api, type Me } from "./api";

type AuthCtx = {
  me: Me | null;
  loading: boolean;
  refresh: () => Promise<void>;
  logout: () => Promise<void>;
};

const Ctx = createContext<AuthCtx | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [me, setMe] = useState<Me | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = async () => {
    try {
      const m = await api.get<Me>("/api/auth/me");
      setMe(m);
    } catch {
      setMe(null);
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    await api.post("/api/auth/logout");
    setMe(null);
  };

  useEffect(() => {
    refresh();
  }, []);

  return <Ctx.Provider value={{ me, loading, refresh, logout }}>{children}</Ctx.Provider>;
}

export function useAuth() {
  const v = useContext(Ctx);
  if (!v) throw new Error("useAuth outside AuthProvider");
  return v;
}
