locals {
  services = ["frontend", "backend", "postgres", "redis"]
}

resource "aws_cloudwatch_log_group" "this" {
  for_each          = toset(local.services)
  name              = "/ecs/${var.project}/${each.value}"
  retention_in_days = 14 # short retention — cost guardrail
}
