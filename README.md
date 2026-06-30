# ShopNow — Poly-Orchestrator Benchmark: ECS (Fargate) vs EKS (Fargate)

Benchmark of **AWS ECS Fargate** against **Amazon EKS Fargate** by deploying the **same**
3-tier "ShopNow" inventory application to both orchestrators and comparing them on service
discovery, load balancing, resiliency, autoscaling, operability, and cost.

> **Fairness principle.** The app is built **once**. One set of immutable image digests is pushed
> to ECR and the **exact same images** are deployed to both ECS and EKS. The orchestrator is the
> only variable. Every environment-specific value (DB host, Redis URL, backend discovery name,
> secrets) is injected at **runtime** — never baked into an image.

---

## Architecture

```
                          Internet
                              │
                   ┌──────────▼───────────┐
                   │   Application LB      │   (one per platform)
                   └──────────┬───────────┘
                              │  :80  → :8080
                   ┌──────────▼───────────┐
                   │  Frontend (Nginx +   │   serves React SPA
                   │  built React assets) │   reverse-proxies /api/*
                   └──────────┬───────────┘
                              │  internal service discovery
        ECS: backend.shopnow.local (Cloud Map)   │   EKS: backend (ClusterIP DNS)
                   ┌──────────▼───────────┐
                   │   Backend (Express)  │   REST CRUD, cache-aside
                   └─────┬───────────┬────┘
                         │           │
              ┌──────────▼──┐   ┌────▼─────────┐
              │  Postgres   │   │    Redis     │   (containers in-cluster;
              └─────────────┘   └──────────────┘    prod → RDS + ElastiCache)
```

Full diagram and request flow: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

The **frontend container is the service-discovery seam**: Nginx serves the static React build and
reverse-proxies `/api/*` to the backend by an internal name that differs only in *value* per
platform — `backend.shopnow.local` (ECS Cloud Map) vs `backend` (EKS ClusterIP DNS). The image is
identical; the name is supplied via env var / ConfigMap and templated into the Nginx config at
container start.

---

## Repository layout

| Path | What |
|------|------|
| `backend/` | Node.js + Express REST API (products CRUD, Redis cache-aside, `/healthz` + `/readyz`) |
| `frontend/` | React (Vite) UI served by Nginx; proxies `/api` to the backend |
| `docker-compose.yml` | Local 3-tier stack for verification |
| `terraform/bootstrap/` | S3 remote-state bucket (run once) |
| `terraform/network/` | VPC, 2×public + 2×private subnets, 1 NAT GW, VPC endpoints, SG for endpoints |
| `terraform/ecr/` | ECR repositories (scan-on-push, immutable tags, lifecycle policies) |
| `terraform/ecs/` | ECS cluster, task defs, services, Cloud Map, ALB, Service Auto Scaling |
| `terraform/eks/` | EKS cluster, Fargate profiles, IRSA, ALB controller, metrics-server |
| `kubernetes/` | Deployment, Service, Ingress, ConfigMap, Secret, HPA (+ kustomize) |
| `.github/workflows/` | `ci.yml`, `deploy.yml`, `teardown.yml` (GitHub OIDC → IAM) |
| `docs/` | Architecture, deployment, comparison, cost, resiliency, security, lessons |

---

## Quick start (local)

```bash
cp .env.example .env          # set a local DB password
docker compose up --build     # frontend :8080, backend :8081
```

Verify:
```bash
curl localhost:8081/readyz                       # {"status":"ready", ...}
curl -X POST localhost:8080/api/products \       # create via the Nginx /api proxy
  -H 'Content-Type: application/json' \
  -d '{"name":"Keyboard","sku":"KB-01","quantity":3,"priceCents":1999}'
curl -D - localhost:8080/api/products -o /dev/null | grep -i x-cache   # MISS, then HIT
```

Open <http://localhost:8080> for the UI (dashboard + add/edit/delete).

Tests:
```bash
cd backend  && npm ci && npm test     # Jest unit + supertest API
cd frontend && npm ci && npm test     # Vitest + React Testing Library
```

---

## Deploy to AWS

Full runbook: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md). In short:

```bash
# 0. Authenticate to AWS (per your org's workflow), then:
# 1. Remote state (once)
terraform -chdir=terraform/bootstrap apply -var state_bucket_name=<unique-bucket>
cp terraform/backend.hcl.example terraform/backend.hcl    # set bucket name

# 2. Shared network + registry
terraform -chdir=terraform/network init -backend-config=../backend.hcl && terraform -chdir=terraform/network apply
terraform -chdir=terraform/ecr    init -backend-config=../backend.hcl && terraform -chdir=terraform/ecr    apply

# 3. Build & push images (or let CI do it) — same tag to both platforms
# 4. ECS + EKS
terraform -chdir=terraform/ecs init -backend-config=../backend.hcl && terraform -chdir=terraform/ecs apply -var state_bucket=<bucket> -var image_tag=<sha>
terraform -chdir=terraform/eks init -backend-config=../backend.hcl && terraform -chdir=terraform/eks apply -var state_bucket=<bucket>
kubectl apply -k kubernetes/
```

> **Cost warning.** The EKS control plane (~$0.10/hr) and the NAT Gateway bill while they exist.
> Run the **Teardown** workflow (or `terraform destroy`) between sessions. See [docs/COST.md](docs/COST.md).

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md) — components, request flow, service discovery
- [Deployment](docs/DEPLOYMENT.md) — step-by-step for local, ECS, EKS, CI/CD, OIDC setup
- [ECS vs EKS comparison](docs/COMPARISON.md) — the benchmark findings
- [Cost](docs/COST.md) — cost model and optimizations
- [Resiliency](docs/RESILIENCY.md) — kill-a-task / kill-a-pod recovery demos
- [Security](docs/SECURITY.md) — secrets, OIDC, least privilege, containers
- [Lessons learned](docs/LESSONS_LEARNED.md)

## Tech stack
React · Node/Express · PostgreSQL · Redis · Docker · Terraform · AWS ECS Fargate · AWS EKS Fargate ·
Cloud Map · ALB · ECR · Secrets Manager · GitHub Actions (OIDC).
