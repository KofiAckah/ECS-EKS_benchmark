locals {
  ns = aws_service_discovery_private_dns_namespace.this.name
  log_opts = { for s in local.services : s => {
    "awslogs-group"         = aws_cloudwatch_log_group.this[s].name
    "awslogs-region"        = var.region
    "awslogs-stream-prefix" = "ecs"
  } }
}

# ---- Postgres (ephemeral; production would use RDS) ----
resource "aws_ecs_task_definition" "postgres" {
  family                   = "${var.project}-postgres"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name         = "postgres"
    image        = "postgres:16-alpine"
    essential    = true
    portMappings = [{ containerPort = 5432, protocol = "tcp" }]
    environment = [
      { name = "POSTGRES_USER", value = var.db_user },
      { name = "POSTGRES_DB", value = var.db_name },
      { name = "PGDATA", value = "/var/lib/postgresql/data/pgdata" },
    ]
    secrets = [
      { name = "POSTGRES_PASSWORD", valueFrom = aws_secretsmanager_secret.db_password.arn },
    ]
    logConfiguration = { logDriver = "awslogs", options = local.log_opts["postgres"] }
    healthCheck = {
      command     = ["CMD-SHELL", "pg_isready -U ${var.db_user} -d ${var.db_name}"]
      interval    = 10
      timeout     = 5
      retries     = 5
      startPeriod = 20
    }
  }])
}

# ---- Redis ----
resource "aws_ecs_task_definition" "redis" {
  family                   = "${var.project}-redis"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name             = "redis"
    image            = "redis:7-alpine"
    essential        = true
    command          = ["redis-server", "--save", "", "--appendonly", "no"]
    portMappings     = [{ containerPort = 6379, protocol = "tcp" }]
    logConfiguration = { logDriver = "awslogs", options = local.log_opts["redis"] }
    healthCheck = {
      command     = ["CMD", "redis-cli", "ping"]
      interval    = 10
      timeout     = 5
      retries     = 5
      startPeriod = 10
    }
  }])
}

# ---- Backend API ----
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name         = "backend"
    image        = local.backend_image
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "PORT", value = "8080" },
      { name = "DB_HOST", value = "postgres.${local.ns}" },
      { name = "DB_PORT", value = "5432" },
      { name = "DB_USER", value = var.db_user },
      { name = "DB_NAME", value = var.db_name },
      { name = "REDIS_URL", value = "redis://redis.${local.ns}:6379" },
      { name = "CACHE_TTL_SECONDS", value = tostring(var.cache_ttl_seconds) },
    ]
    secrets = [
      { name = "DB_PASSWORD", valueFrom = aws_secretsmanager_secret.db_password.arn },
    ]
    logConfiguration = { logDriver = "awslogs", options = local.log_opts["backend"] }
    healthCheck = {
      command     = ["CMD-SHELL", "node -e \"fetch('http://127.0.0.1:8080/healthz').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))\""]
      interval    = 15
      timeout     = 5
      retries     = 3
      startPeriod = 30
    }
  }])
}

# ---- Frontend (Nginx + React); BACKEND_HOST points at Cloud Map ----
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name         = "frontend"
    image        = local.frontend_image
    essential    = true
    portMappings = [{ containerPort = 8080, protocol = "tcp" }]
    environment = [
      { name = "BACKEND_HOST", value = "backend.${local.ns}" }, # Cloud Map discovery
      { name = "BACKEND_PORT", value = "8080" },
      { name = "DNS_RESOLVER", value = "169.254.169.253" }, # VPC Route 53 Resolver
    ]
    logConfiguration = { logDriver = "awslogs", options = local.log_opts["frontend"] }
    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://127.0.0.1:8080/healthz >/dev/null 2>&1 || exit 1"]
      interval    = 15
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
  }])
}
