# Least-privilege SGs: each tier accepts traffic ONLY from the tier in front of
# it. ALB ← internet, frontend ← ALB, backend ← frontend, data ← backend.

resource "aws_security_group" "alb" {
  name_prefix = "${var.project}-alb-"
  description = "Public ALB"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "frontend" {
  name_prefix = "${var.project}-fe-"
  description = "Frontend (Nginx) tasks"
  vpc_id      = local.vpc_id

  ingress {
    description     = "App port from ALB only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "backend" {
  name_prefix = "${var.project}-be-"
  description = "Backend API tasks"
  vpc_id      = local.vpc_id

  ingress {
    description     = "App port from frontend only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "data" {
  name_prefix = "${var.project}-data-"
  description = "Postgres + Redis tasks"
  vpc_id      = local.vpc_id

  ingress {
    description     = "Postgres from backend only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
  ingress {
    description     = "Redis from backend only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle { create_before_destroy = true }
}
