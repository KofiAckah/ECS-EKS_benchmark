variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "shopnow"
}

locals {
  repos = ["frontend", "backend"]
}

resource "aws_ecr_repository" "this" {
  for_each = toset(local.repos)

  name                 = "${var.project}/${each.value}"
  image_tag_mutability = "IMMUTABLE" # tags = git SHA; never overwritten

  image_scanning_configuration {
    scan_on_push = true # surface CVEs on every push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Expire untagged images so the registry doesn't accumulate cost over time.
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the 20 most recent tagged images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = { type = "expire" }
      }
    ]
  })
}

output "repository_urls" {
  value = { for k, r in aws_ecr_repository.this : k => r.repository_url }
}
