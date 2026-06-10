# DreamTeam web — self-contained image for local, persistent deployment.
# The SQLite database lives at /data (a mounted volume), so it survives
# container restarts/recreations. Express serves the API + built React SPA
# and runs the FIFA sync cron in-process.
FROM node:22-slim

# Prisma's query engine needs OpenSSL at runtime.
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install dependencies. Dev deps are needed to build (vite/tsc) and for the
# Prisma CLI used at startup to sync the schema into the volume.
COPY package*.json ./
COPY prisma ./prisma
RUN npm ci --include=dev

# Build the client + server and generate the Prisma client.
COPY . .
RUN npx prisma generate \
  && npm run build:client \
  && npm run build:server

# SQLite DB path on the persistent volume (absolute, so it's cwd-independent).
ENV NODE_ENV=production
ENV PORT=3000
ENV DATABASE_URL=file:/data/dev.db
RUN mkdir -p /data
VOLUME ["/data"]

EXPOSE 3000

# On every start: ensure the schema exists in the volume (idempotent no-op when
# already in sync), then launch the server.
CMD ["sh", "-c", "npx prisma db push --skip-generate --accept-data-loss && node dist/server/index.js"]
