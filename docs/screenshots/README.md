# Screenshots

Capture these for the submission / portfolio:

1. **Local** — `docker compose` running; the ShopNow UI with products; `X-Cache: HIT` in devtools.
2. **ECS** — cluster + services (desired=running), Cloud Map namespace, ALB URL serving the app.
3. **EKS** — `kubectl get pods/svc/ingress -n shopnow`, the Ingress ALB serving the app.
4. **Same image proof** — ECS task def image digest == EKS pod image digest (the fairness claim).
5. **Resiliency** — before/after killing a task (ECS) and a pod (EKS); recovery to desired count.
6. **Autoscaling** — ECS Service Auto Scaling and EKS HPA scaling out under load.

Drop the image files in this folder and reference them from the docs.
