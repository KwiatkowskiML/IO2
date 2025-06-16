output "s3_bucket_name" {
  description = "The name of the S3 bucket for the frontend static files."
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}
