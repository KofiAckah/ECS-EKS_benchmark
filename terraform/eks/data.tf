data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "network/terraform.tfstate"
    region = var.region
  }
}

locals {
  vpc_id          = data.terraform_remote_state.network.outputs.vpc_id
  private_subnets = data.terraform_remote_state.network.outputs.private_subnet_ids
  public_subnets  = data.terraform_remote_state.network.outputs.public_subnet_ids
  cluster_name    = "${var.project}-eks"
}
