variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-2" # Or your preferred region
}

variable "project_name_prefix" {
  description = "A prefix for all resource names to ensure uniqueness and organization"
  type        = string
  default     = "YOUR-project_name_prefix"
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket"
  type        = string
  default     = "YOUR-s3_bucket_name" # MUST BE GLOBALLY UNIQUE
}

variable "instance_type" {
  description = "EC2 instance type for the ML server"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (e.g., Ubuntu LTS)"
  type        = string
  default     = "ami-053b0a701a5113cd1" # Example for Ubuntu 22.04 LTS in us-east-1, check latest
}