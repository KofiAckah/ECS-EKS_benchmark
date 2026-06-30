# VPC endpoints keep image pulls and logging off the NAT Gateway, cutting NAT
# data-processing charges (cost optimization) and reducing the public attack
# surface. S3 is a free Gateway endpoint; the rest are Interface endpoints.

resource "aws_security_group" "endpoints" {
  name_prefix = "${var.project}-vpce-"
  description = "Allow HTTPS from within the VPC to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Gateway endpoint (free) — S3, used by ECR layer storage.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}

locals {
  interface_endpoints = [
    "ecr.api", # ECR control plane
    "ecr.dkr", # ECR image pulls
    "logs",    # CloudWatch Logs
    "sts",     # IRSA / task-role token vending
    "secretsmanager",
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
}
