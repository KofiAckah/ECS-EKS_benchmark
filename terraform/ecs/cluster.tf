resource "aws_ecs_cluster" "this" {
  name = "${var.project}-ecs"

  setting {
    name  = "containerInsights"
    value = "enabled" # observability parity with EKS metrics
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# Private DNS namespace for Cloud Map service discovery: <svc>.shopnow.local
resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = local.namespace_name
  description = "ShopNow internal service discovery"
  vpc         = local.vpc_id
}

# Discoverable internal services. Frontend is NOT here — it is reached via the ALB.
resource "aws_service_discovery_service" "internal" {
  for_each = toset(["backend", "postgres", "redis"])

  name = each.value

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
