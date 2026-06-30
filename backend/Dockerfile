# syntax=docker/dockerfile:1

# ---- deps: install production dependencies only ----
FROM node:20-slim AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

# ---- runtime ----
FROM node:20-slim AS runtime
ENV NODE_ENV=production \
    PORT=8080
WORKDIR /app

# Run as the unprivileged "node" user that ships with the base image.
COPY --chown=node:node --from=deps /app/node_modules ./node_modules
COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src

USER node
EXPOSE 8080

# Liveness probe baked into the image; orchestrators also probe /healthz.
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||8080)+'/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "src/server.js"]
