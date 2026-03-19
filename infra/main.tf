terraform {
  backend "s3" {
    bucket = "admin-terraform-state-638661062945"
    key    = "cloud-resume-challenge.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}


provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "frontend" {
  source             = "./modules/s3_cloudfront"
  project_name       = var.project_name
  aws_region         = var.aws_region
  cloudflare_zone_id = var.cloudflare_zone_id
  domain_name        = var.domain_name
}

module "backend" {
  source       = "./modules/backend_api"
  project_name = var.project_name
}

module "oidc" {
  source         = "./modules/oidc"
  project_name   = var.project_name
  github_org     = var.github_org
  github_repo    = var.github_repo
  s3_bucket_arn  = module.frontend.bucket_arn
  cloudfront_arn = module.frontend.cloudfront_arn
  lambda_arn     = module.backend.lambda_function_arn
}
