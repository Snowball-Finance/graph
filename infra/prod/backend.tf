locals {
  state_bucket  = "prod-snowball-terraform-state"
  vpc_state_key = "vpc.tfstate"
  project       = "snowball"
  node          = "graph-node"
  env           = "prod"
  domain_name   = "graph"
  node_port     = 8000
}

provider "aws" {
  region = "us-west-2"
}

terraform {
  required_providers {
    aws = { 
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    encrypt        = true
    key            = "graph.tfstate"
    bucket         = "prod-snowball-terraform-state"
    dynamodb_table = "prod-snowball-terraform-state-lock"
    region         = "us-west-2"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "us-west-2"
    bucket = local.state_bucket
    key    = local.vpc_state_key
  }
}
