# CLAUDE.md — ShopNow Poly-Orchestrator Benchmark

Project guidance for Claude Code when working in this repo.

## What this is
A DevOps lab benchmarking **AWS ECS (Fargate)** vs **Amazon EKS (Fargate)** by deploying the
**same** 3-tier "ShopNow" inventory app to both. Graded against `Requirements.txt`; spec in
`ECS vs EKS benchmark.md`.

## Non-negotiable principle
Build the app **once**, push **one set of immutable image digests** to ECR, deploy the **exact
same images** to both ECS and EKS. The orchestrator is the only variable. All environment-specific
values (DB host, Redis URL, backend discovery name, secrets) are injected at **runtime** via env
vars / ConfigMaps / Secrets — never baked into an image.

## Architecture
- **frontend/** — React (Vite) static build served by **Nginx**; Nginx reverse-proxies `/api/*` to
  the backend over internal service discovery. Upstream host is templated from `$BACKEND_HOST` at
  container start (envsubst). Same image works in ECS and EKS.
- **backend/** — Node.js + Express REST API. Products CRUD over Postgres; Redis cache-aside on the
  listing. Health: `/healthz` (liveness), `/readyz` (readiness: checks DB + Redis).
- **Postgres + Redis** — run as containers/tasks in both platforms (lab simplification; production
  would use RDS + ElastiCache).
- Public path: **Internet → ALB → Frontend (Nginx) → [Cloud Map / ClusterIP DNS] → Backend → PG/Redis**.

## Service discovery (the comparison point)
- ECS: backend in **AWS Cloud Map** → `backend.shopnow.local`.
- EKS: backend **ClusterIP Service** → `backend` / `backend.shopnow.svc.cluster.local`.

## Conventions
- Node 20, CommonJS. Backend tests: Jest + supertest (`npm test`). Frontend: Vitest + RTL.
- Containers run **non-root**, include `HEALTHCHECK`, multi-stage builds, minimal bases.
- Image tags = git SHA (immutable). No `:latest` in deploys.
- Terraform under `terraform/` with remote state (S3 + DynamoDB). `network/`, `ecr/`, `ecs/`, `eks/`.
- CI/CD: GitHub Actions, auth via **GitHub OIDC → IAM role** (no static AWS keys).
- No secrets in git. Secrets Manager (ECS) / K8s Secret (EKS).

## Verify locally
`docker compose up --build` → open frontend, do CRUD, confirm `X-Cache` HIT/MISS and `/readyz` green.

## Cost guardrails
Single NAT GW; VPC endpoints (ECR/S3/logs); ECR lifecycle policies; `teardown.yml` runs
`terraform destroy`. EKS control plane + NAT bill while clusters are up — tear down between sessions.
