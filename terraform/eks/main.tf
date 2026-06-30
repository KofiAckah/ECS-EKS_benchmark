module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # Fargate-only cluster (no EC2 node groups) — mirrors ECS Fargate so the
  # orchestrator is the only variable in the benchmark.
  fargate_profiles = {
    kube-system = {
      name      = "kube-system"
      selectors = [{ namespace = "kube-system" }]
    }
    app = {
      name      = "app"
      selectors = [{ namespace = var.app_namespace }]
    }
  }

  # Managed addons. CoreDNS is told to run on Fargate (computeType), otherwise
  # its pods stay Pending on a node-less cluster and cluster DNS never comes up.
  cluster_addons = {
    coredns = {
      most_recent          = true
      configuration_values = jsonencode({ computeType = "Fargate" })
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
}
