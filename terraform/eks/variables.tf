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
  description = "Remote-state bucket holding the network state."
}

variable "cluster_version" {
  type    = string
  default = "1.30"
}

variable "app_namespace" {
  type    = string
  default = "shopnow"
}
