# Lessons Learned

## What worked well
- **Build once, deploy everywhere.** Keeping every environment-specific value out of the image (DB
  host, Redis URL, backend discovery name, secrets) meant the *exact same digest* ran locally, on
  ECS, and on EKS. This is what makes the benchmark fair — and it's just 12-factor discipline.
- **Nginx-as-the-frontend** turned a pure SPA into a real server-to-server service-discovery
  demonstration, satisfying the lab requirement that "the frontend talks to the backend via service
  discovery" rather than the browser calling a public API.
- **Holding compute constant (Fargate on both)** made the comparison about the orchestrator, not the
  compute model — a cleaner experiment.

## What was harder than expected
- **EKS Ingress on Fargate was the biggest time sink.** It needs the AWS Load Balancer Controller
  (Helm) + an OIDC provider + IRSA, and **`target-type: ip`** is mandatory because Fargate pods have
  no node NodePorts. ECS wired its ALB to the service in a few lines of Terraform by comparison.
- **CoreDNS on a node-less cluster.** A Fargate-only cluster has nothing to schedule CoreDNS on, so
  cluster DNS silently fails until the addon is set to `computeType: Fargate` and a `kube-system`
  Fargate profile exists. ECS had no equivalent gotcha.
- **DNS re-resolution for Cloud Map.** Cloud Map A-records point at task IPs that change on
  reschedule, so Nginx had to use a `resolver` + variable `proxy_pass` to re-resolve. On EKS the
  ClusterIP is stable, so a plain `proxy_pass` was enough — a subtle but real difference.

## If I did it again
- Add an **HTTPS listener** (ACM cert) and HTTP→HTTPS redirect from day one.
- Wire **External Secrets Operator** on EKS so the K8s Secret is sourced from Secrets Manager,
  matching the ECS path exactly (no demo secret in git).
- Add a **load-generation step** to the resiliency/HPA demo to show scale-out under real traffic.
- Consider an **internal ALB** instead of Cloud Map on ECS to compare a second discovery style.

## Headline takeaway
For a small product like ShopNow, **ECS Fargate** gives the lowest operational and baseline cost. The
moment you need the Kubernetes ecosystem, multi-cloud portability, or many teams sharing a platform,
**EKS** earns its control-plane premium — and at sustained scale, moving EKS to EC2 node groups
changes the economics again. The right answer is workload- and team-dependent, which is exactly why
benchmarking both on the same app was worth doing.
