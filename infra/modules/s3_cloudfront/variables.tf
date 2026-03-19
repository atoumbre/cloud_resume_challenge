variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for atoumbre.me"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name"
  type        = string
}
