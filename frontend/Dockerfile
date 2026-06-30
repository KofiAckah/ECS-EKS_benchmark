# syntax=docker/dockerfile:1

# ---- build: compile the React app to static assets ----
FROM node:20-slim AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci
COPY . .
RUN npm run build

# ---- runtime: unprivileged nginx serving static assets + /api proxy ----
# nginx-unprivileged runs as uid 101 and listens on 8080 by default — no root.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

# Defaults; overridden per platform at runtime (env vars / ConfigMap).
ENV BACKEND_HOST=backend \
    BACKEND_PORT=8080 \
    DNS_RESOLVER=127.0.0.11 \
    NGINX_ENVSUBST_FILTER="^(BACKEND_HOST|BACKEND_PORT|DNS_RESOLVER)$"

# Template is rendered to /etc/nginx/conf.d/default.conf by the base image's
# /docker-entrypoint.d/20-envsubst-on-templates.sh at container start.
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD ["sh", "-c", "wget -qO- http://127.0.0.1:8080/healthz >/dev/null 2>&1 || exit 1"]
