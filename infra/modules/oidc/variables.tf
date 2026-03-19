variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "github_org" {
  description = "GitHub username or organization name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket to allow access to"
  type        = string
}

variable "cloudfront_arn" {
  description = "ARN of the CloudFront distribution to allow invalidation"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function to update"
  type        = string
}
