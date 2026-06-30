# ECS Service Auto Scaling — the ECS equivalent of the Kubernetes HPA. Both
# scale on CPU target tracking so the comparison is apples-to-apples.
locals {
  scalable = {
    frontend = aws_ecs_service.frontend.name
    backend  = aws_ecs_service.backend.name
  }
}

resource "aws_appautoscaling_target" "this" {
  for_each = local.scalable

  max_capacity       = 6
  min_capacity       = var.desired_count
  resource_id        = "service/${aws_ecs_cluster.this.name}/${each.value}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  for_each = local.scalable

  name               = "${each.key}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.this[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60
    scale_in_cooldown  = 120
    scale_out_cooldown = 60
  }
}
