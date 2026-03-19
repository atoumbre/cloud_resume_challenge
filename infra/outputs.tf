output "website_url" {
  description = "The URL of the website static endpoint"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront Distribution Domain Name"
  value       = module.frontend.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = module.frontend.cloudfront_distribution_id
}

output "frontend_s3_bucket_name" {
  description = "S3 Bucket Name for Frontend"
  value       = module.frontend.bucket_name
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = module.backend.api_endpoint
}

output "lambda_function_name" {
  description = "Lambda Function Name"
  value       = module.backend.lambda_function_name
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions OIDC"
  value       = module.oidc.github_actions_role_arn
}

output "acm_validation_records" {
  description = "CNAME records to create in Cloudflare for SSL certificate validation"
  value       = module.frontend.acm_validation_records
}
