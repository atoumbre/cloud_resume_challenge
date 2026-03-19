
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

# Cloudflare Configuration

variable "cloudflare_api_token" {
  description = "Cloudflare API Token for DNS Automation"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for atoumbre.me"
  type        = string
}

