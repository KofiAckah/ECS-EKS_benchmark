data "aws_caller_identity" "current" {}

# Consume the shared network and ECR registry from remote state.
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "network/terraform.tfstate"
    region = var.region
  }
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "ecr/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  vpc_cidr        = data.terraform_remote_state.network.outputs.vpc_cidr
  public_subnets  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnets = data.terraform_remote_state.network.outputs.private_subnet_ids

  frontend_image = "${data.terraform_remote_state.ecr.outputs.repository_urls["frontend"]}:${var.image_tag}"
  backend_image  = "${data.terraform_remote_state.ecr.outputs.repository_urls["backend"]}:${var.image_tag}"

  namespace_name = "${var.project}.local"
}
