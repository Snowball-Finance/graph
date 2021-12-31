locals {
  remote_state_bucket  = "dev-snowball-terraform-state"
  backend_region       = "us-west-2"
  vpc_remote_state_key = "vpc.tfstate"
}

provider "aws" {
  region  = "us-west-2"
  version = "3.22"
}

terraform {
  
  backend "s3" {
    encrypt        = true
    key            = "the-graph.tfstate"
    bucket         = "dev-snowball-terraform-state"
    dynamodb_table = "dev-snowball-terraform-state-lock"
    region         = "us-west-2"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = local.backend_region
    bucket = local.remote_state_bucket
    key    = local.vpc_remote_state_key
  }
}
