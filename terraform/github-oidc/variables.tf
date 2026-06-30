variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "shopnow"
}

variable "github_owner" {
  type    = string
  default = "KofiAckah"
}

variable "github_repo" {
  type    = string
  default = "ECS-EKS_benchmark"
}

variable "allowed_branch" {
  type        = string
  default     = "main"
  description = "Only workflows on this branch may assume the deploy role."
}

variable "state_bucket" {
  type        = string
  description = "Terraform remote-state bucket the CI role may read/write."
  default     = "shopnow-tfstate-412381768295-euw1"
}
