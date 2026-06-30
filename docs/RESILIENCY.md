# Resiliency Demonstration

The lab requires manually killing a container/pod in **both** environments and showing automatic
recovery. Both orchestrators reconcile actual state toward desired state.

## ECS Fargate — kill a task

```bash
CLUSTER=shopnow-ecs
# 1. Observe desired vs running
aws ecs describe-services --cluster $CLUSTER --services backend \
  --query 'services[0].{desired:desiredCount,running:runningCount}'

# 2. Kill one running backend task
TASK=$(aws ecs list-tasks --cluster $CLUSTER --service-name backend \
  --query 'taskArns[0]' --output text)
aws ecs stop-task --cluster $CLUSTER --task $TASK --reason "resiliency demo"

# 3. Watch ECS relaunch it back to desired count
watch -n2 "aws ecs describe-services --cluster $CLUSTER --services backend \
  --query 'services[0].{desired:desiredCount,running:runningCount}'"
```
**Expected:** `runningCount` dips, then the ECS service scheduler starts a replacement task and
returns to `desiredCount`. The app stays reachable through the ALB because the other replica(s) keep
serving and the target group only routes to healthy targets.

## EKS Fargate — kill a pod

```bash
kubectl -n shopnow get pods -l app=backend -w   # in one terminal

# in another:
POD=$(kubectl -n shopnow get pod -l app=backend -o jsonpath='{.items[0].metadata.name}')
kubectl -n shopnow delete pod $POD
```
**Expected:** the Deployment's ReplicaSet immediately creates a new pod (new Fargate microVM) to
restore `replicas`. Because each Fargate pod is scheduled fresh, the replacement takes longer to
become `Ready` than an EC2-backed pod would — visible in the `-w` output.

## What to capture for the submission
For each platform, screenshot: (a) steady state, (b) the moment after the kill (count down / pod
`Terminating`), (c) recovery to desired state, and (d) the app still responding via its load
balancer throughout. A `curl` loop against the ALB/Ingress during the kill makes the zero/low
downtime visible.

```bash
while true; do curl -s -o /dev/null -w "%{http_code} " <LB_URL>/api/products; sleep 1; done
```
