import express from "express";
import cookieParser from "cookie-parser";
import path from "node:path";
import { fileURLToPath } from "node:url";
import authRoutes from "./routes/auth.js";
import playerRoutes from "./routes/players.js";
import squadRoutes from "./routes/squad.js";
import bidRoutes from "./routes/bids.js";
import standingsRoutes from "./routes/standings.js";
import paperTalkRoutes from "./routes/paperTalk.js";
import graphRoutes from "./routes/graphs.js";
import adminRoutes from "./routes/admin.js";
import tickerRoutes from "./routes/ticker.js";
import fixtureRoutes from "./routes/fixtures.js";
import { startScheduler } from "./scheduler.js";
import { startBackups } from "./backup.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const app = express();
app.use(express.json());
app.use(cookieParser());

app.use("/api/auth", authRoutes);
app.use("/api/players", playerRoutes);
app.use("/api/squad", squadRoutes);
app.use("/api/bids", bidRoutes);
app.use("/api/standings", standingsRoutes);
app.use("/api/paper-talk", paperTalkRoutes);
app.use("/api/graphs", graphRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/ticker", tickerRoutes);
app.use("/api/fixtures", fixtureRoutes);

app.get("/api/health", (_req, res) => res.json({ ok: true }));

// In production, serve the built client. In dev, Vite serves it on :5173.
const clientDist = path.resolve(__dirname, "../client");
import("node:fs").then(({ existsSync }) => {
  if (existsSync(path.join(clientDist, "index.html"))) {
    app.use(express.static(clientDist));
    app.get(/^\/(?!api).*/, (_req, res) => {
      res.sendFile(path.join(clientDist, "index.html"));
    });
  } else {
    app.get(/^\/(?!api).*/, (_req, res) => {
      res
        .status(404)
        .type("text/plain")
        .send("Dev mode: open http://localhost:5173 — Vite serves the client there.");
    });
  }
});

const port = Number(process.env.PORT ?? 3000);
app.listen(port, () => {
  console.log(`[server] http://localhost:${port}`);
  startScheduler();
  startBackups();
});
