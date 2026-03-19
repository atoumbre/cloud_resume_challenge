
# AWS Configuration

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}


variable "project_name" {
  description = "Name of the project"
  type        = string
}

# GitHub OIDC Configuration

variable "github_org" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

