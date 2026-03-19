
# GitHub OIDC Configuration (Required for role scoping)

variable "github_org" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

# AWS Configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name (optional)"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token for DNS Automation"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for atoumbre.me"
  type        = string
}

