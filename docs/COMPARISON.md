# ECS (Fargate) vs EKS (Fargate) — Benchmark Findings

Both platforms run the **same images** on the **same compute model** (Fargate) in the **same VPC**.
Holding compute constant isolates the **orchestrator** as the only variable.

## Summary scorecard

| Dimension | ECS Fargate | EKS Fargate | Takeaway |
|-----------|-------------|-------------|----------|
| Time to first deploy | Fast — task def + service | Slower — cluster + Fargate profiles + ALB controller + IRSA | ECS wins on ramp-up |
| Service discovery | Cloud Map private DNS (`*.shopnow.local`) | Native ClusterIP + CoreDNS | EKS is simpler/native; ECS is explicit |
| Load balancing | ALB wired directly in Terraform | ALB via Load Balancer Controller + Ingress | ECS fewer moving parts |
| Config / secrets | Task def `secrets` ← Secrets Manager | ConfigMap + Secret (prod: External Secrets) | Comparable |
| Autoscaling | Application Auto Scaling (target tracking) | HPA + metrics-server | Equivalent; HPA needs metrics-server |
| Resiliency | Service relaunches stopped tasks | ReplicaSet recreates deleted pods | Both self-heal automatically |
| Observability | Container Insights (built in) | Needs add-ons (metrics-server, etc.) | ECS lower setup |
| Portability | AWS-specific | Kubernetes-standard (multi-cloud) | EKS wins on portability |
| Ecosystem | AWS-native only | Huge CNCF ecosystem (Helm, operators) | EKS wins on extensibility |
| Control-plane cost | $0 | ~$0.10/hr (~$72/mo) | ECS wins on baseline cost |
| Operational surface | Low | Higher (cluster + controllers + add-ons + version upgrades) | ECS lower ops |

## Where the platforms diverge in *this* project

**Service discovery.** On ECS the backend is registered in a **Cloud Map** private DNS namespace and
the frontend's Nginx proxies to `backend.shopnow.local`; because Cloud Map A-records point at task
IPs that change on reschedule, Nginx re-resolves on a short TTL. On EKS the backend is a **ClusterIP
Service** with a stable virtual IP, so `proxy_pass http://backend:8080` "just works" and kube-proxy
handles pod churn. EKS's discovery is more transparent; ECS's is more explicit but needs a NAT/VPC
endpoint and a resolver.

**Load balancing.** ECS lets Terraform attach the ALB target group to the service directly. EKS
requires installing the **AWS Load Balancer Controller** (Helm + IRSA + OIDC) and, **because the
cluster is Fargate, `target-type: ip`** — this was the single biggest setup cost.

**CoreDNS on Fargate.** A Fargate-only EKS cluster has no nodes, so CoreDNS stays `Pending` unless
the addon is told to run on Fargate (`computeType: Fargate`) and a `kube-system` Fargate profile
exists. ECS has no equivalent footgun.

## When to choose which
- **Choose ECS Fargate** when the team is small, the workload is a handful of services, you want the
  lowest ops overhead and no control-plane cost, and you're committed to AWS.
- **Choose EKS** when you need the Kubernetes ecosystem (Helm charts, operators, CRDs), multi-cloud
  portability, advanced scheduling, or a platform many teams share.

## Note on the EKS-on-EC2 alternative (not built)
We deliberately ran EKS on **Fargate** to keep the benchmark apples-to-apples. In production, **EKS
on managed EC2 node groups** is often cheaper at sustained scale and removes Fargate limitations
(DaemonSets, faster pod start, GPU/large pods), at the cost of managing node lifecycle, patching,
and bin-packing. That tradeoff — serverless simplicity vs node-level control/cost — is the real
ECS-vs-EKS decision once compute is no longer held constant.
