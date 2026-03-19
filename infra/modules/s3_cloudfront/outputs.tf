output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.website_bucket.bucket
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.website_bucket.arn
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.id
}

output "cloudfront_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cdn.arn
}
