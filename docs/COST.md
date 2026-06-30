# Cost Analysis

> Figures are approximate `us-east-1` on-demand rates for **illustration** — confirm against the
> AWS Pricing Calculator for your region. The goal is the *shape* of the cost difference.

## Baseline (control plane / fixed)

| Item | ECS Fargate | EKS Fargate |
|------|-------------|-------------|
| Orchestrator control plane | **$0** | **~$0.10/hr ≈ $72/mo** |
| NAT Gateway (1×) | ~$0.045/hr ≈ $32/mo + data | same |
| ALB (1×) | ~$0.0225/hr ≈ $16/mo + LCU | same |

The headline structural difference: **EKS bills ~$72/mo for the control plane even when idle; ECS
does not.** For a small app, that single line often decides the comparison.

## Per-workload (Fargate compute)

Fargate is billed per vCPU-hour and GB-hour, identical on both platforms. With the task sizes here
(frontend/backend 0.25 vCPU / 0.5 GB; postgres 0.5 vCPU / 1 GB), running ~2 replicas of each is a
few dollars/day. **Because both platforms use Fargate, compute cost is ~equal** — the comparison
isolates control-plane + ecosystem cost, exactly as intended.

## Optimizations applied in this project

1. **Single NAT Gateway** (not per-AZ) — saves ~$32/mo per extra AZ.
2. **VPC endpoints** (ECR api/dkr, S3 gateway, Logs, STS, Secrets Manager) — image pulls, logs, and
   secret fetches bypass the NAT Gateway, cutting per-GB NAT data-processing charges. S3/ECR layer
   traffic is the bulk of pull bandwidth, so this is the highest-impact saver.
3. **ECR lifecycle policies** — expire untagged images after 7 days; keep only the last 20 tagged.
4. **Short CloudWatch log retention** (14 days).
5. **Containers for Postgres/Redis** instead of RDS + ElastiCache — appropriate for a lab/benchmark;
   documented as a simplification (production would use managed data services).
6. **`teardown.yml` / `terraform destroy`** — the EKS control plane and NAT bill continuously, so
   tearing down between sessions is the biggest real-world saver of all.

## Cost-driven recommendation
For a startup like ShopNow running a handful of services, **ECS Fargate has the lower total cost of
ownership** (no control-plane fee, less operational time). EKS earns its control-plane premium once
you're running many teams/services and leveraging the Kubernetes ecosystem, or when moving to EC2
node groups changes the compute economics at scale.
