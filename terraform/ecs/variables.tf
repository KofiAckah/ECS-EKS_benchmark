variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "project" {
  type    = string
  default = "shopnow"
}

variable "state_bucket" {
  type        = string
  description = "Remote-state bucket holding the network and ecr states."
}

variable "image_tag" {
  type        = string
  description = "Image tag (git SHA) to deploy. Same tag is deployed to EKS."
  default     = "latest"
}

variable "db_name" {
  type    = string
  default = "shopnow"
}

variable "db_user" {
  type    = string
  default = "shopnow"
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "cache_ttl_seconds" {
  type    = number
  default = 30
}
