output "s3_data_lake_bucket_name" {
  description = "Name of the S3 bucket for the data lake"
  value       = aws_s3_bucket.ml_data_lake.bucket
}

output "ec2_ml_server_public_ip" {
  description = "Public IP address of the ML server EC2 instance"
  value       = aws_instance.ml_server.public_ip
}

output "api_gateway_invoke_url" {
  description = "The invoke URL for the deployed API Gateway endpoint."
  # CHANGE THIS LINE:
  value       = aws_api_gateway_stage.api_stage.invoke_url # <--- Corrected
}