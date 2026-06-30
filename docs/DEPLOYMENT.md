# Deployment Runbook

## Prerequisites
- AWS account + credentials (authenticate via your org's workflow before any `terraform`/`aws` call).
- Terraform ≥ 1.10, AWS CLI v2, Docker, `kubectl`, `kustomize`, `helm`.
- An AWS region (default `eu-west-1`; override with `-var region=...` consistently across modules).

## 0. Remote state (run once)
```bash
terraform -chdir=terraform/bootstrap init
terraform -chdir=terraform/bootstrap apply -var state_bucket_name=shopnow-tfstate-412381768295-euw1
cp terraform/backend.hcl.example terraform/backend.hcl
# backend.hcl already points at bucket = shopnow-tfstate-412381768295-euw1
```
State locking uses **S3-native locking** (`use_lockfile = true`, Terraform ≥ 1.10) — no DynamoDB
table required (one fewer billable resource than the legacy lock pattern).

## 1. Network + registry
```bash
terraform -chdir=terraform/network init -backend-config=../backend.hcl
terraform -chdir=terraform/network apply
terraform -chdir=terraform/ecr init -backend-config=../backend.hcl
terraform -chdir=terraform/ecr apply
```

## 2. Build & push images (same tag → both platforms)
Let CI do this (recommended), or manually:
```bash
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGION=eu-west-1; TAG=$(git rev-parse HEAD)
REGISTRY=$ACCOUNT.dkr.ecr.$REGION.amazonaws.com
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY
for s in backend frontend; do
  docker build -t $REGISTRY/shopnow/$s:$TAG ./$s
  docker push  $REGISTRY/shopnow/$s:$TAG
done
```

## 3. ECS (Fargate)
```bash
terraform -chdir=terraform/ecs init -backend-config=../backend.hcl
terraform -chdir=terraform/ecs apply -var state_bucket=shopnow-tfstate-412381768295-euw1 -var image_tag=$TAG
terraform -chdir=terraform/ecs output alb_dns_name      # open this URL
```

## 4. EKS (Fargate)
```bash
terraform -chdir=terraform/eks init -backend-config=../backend.hcl
terraform -chdir=terraform/eks apply -var state_bucket=shopnow-tfstate-412381768295-euw1
aws eks update-kubeconfig --name shopnow-eks --region $REGION

cd kubernetes
kustomize edit set image \
  shopnow/backend=$REGISTRY/shopnow/backend:$TAG \
  shopnow/frontend=$REGISTRY/shopnow/frontend:$TAG
kubectl apply -k .
kubectl -n shopnow get ingress shopnow -w     # wait for the ALB address
```
> If the frontend can't reach the backend on EKS, confirm `DNS_RESOLVER` in
> `kubernetes/01-config-and-secret.yaml` matches your cluster's kube-dns ClusterIP:
> `kubectl -n kube-system get svc kube-dns`.

## 5. CI/CD (GitHub Actions, OIDC — no static keys)
Create an IAM OIDC identity provider for `token.actions.githubusercontent.com` and a role whose
trust policy restricts `sub` to this repo, e.g.:
```
"token.actions.githubusercontent.com:sub": "repo:<owner>/<repo>:ref:refs/heads/main"
```
Attach least-privilege policies for ECR push, ECS/EKS deploy, and Terraform state access. Then set:
- Repo **secret** `AWS_ROLE_ARN` = the role ARN
- Repo **variables** `AWS_REGION`, `TF_STATE_BUCKET`

Pipelines:
- **CI** (`ci.yml`) — lint + test (backend & frontend), `terraform fmt/validate`, build & push images on push to `main`.
- **Deploy** (`deploy.yml`) — after CI succeeds: `terraform apply` ECS with the new tag, and `kustomize set image` + `kubectl apply` on EKS. Same SHA to both.
- **Teardown** (`teardown.yml`) — manual `terraform destroy` (type `destroy` to confirm).

## 6. Teardown (cost guard)
```bash
# reverse order: workloads → network
for m in eks ecs ecr network; do
  terraform -chdir=terraform/$m destroy   # ecs/eks also need -var state_bucket=...
done
```
