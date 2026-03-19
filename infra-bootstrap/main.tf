terraform {
  backend "s3" {
    bucket = "admin-terraform-state-638661062945"
    key    = "cloud-resume-challenge-bootstrap.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "github" {
  owner = var.github_org
}

module "oidc" {
  source       = "./modules/oidc"
  project_name = var.project_name
  github_org   = var.github_org
  github_repo  = var.github_repo
}

locals {
  github_repository_variables = {
    AWS_REGION   = var.aws_region
    AWS_ROLE_ARN = module.oidc.github_actions_role_arn
  }
}

resource "github_actions_variable" "repository" {
  for_each = local.github_repository_variables

  repository    = var.github_repo
  variable_name = each.key
  value         = each.value
}
