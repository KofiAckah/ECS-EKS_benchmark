# Data-tier services (Postgres, Redis): single task each, registered in Cloud Map
# so the backend can reach them by DNS name. In private subnets, no public IP.
resource "aws_ecs_service" "postgres" {
  name            = "postgres"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.postgres.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.data.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.internal["postgres"].arn
  }
}

resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.data.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.internal["redis"].arn
  }
}

# Backend: multiple tasks, discoverable at backend.shopnow.local.
resource "aws_ecs_service" "backend" {
  name            = "backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.backend.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.internal["backend"].arn
  }

  depends_on = [aws_ecs_service.postgres, aws_ecs_service.redis]
}

# Frontend: behind the ALB. No Cloud Map registration needed.
resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.frontend.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http, aws_ecs_service.backend]
}
