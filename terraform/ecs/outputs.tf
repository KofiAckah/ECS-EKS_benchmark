output "alb_dns_name" {
  description = "Public URL of the ShopNow app on ECS"
  value       = "http://${aws_lb.frontend.dns_name}"
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_names" {
  value = {
    frontend = aws_ecs_service.frontend.name
    backend  = aws_ecs_service.backend.name
  }
}
