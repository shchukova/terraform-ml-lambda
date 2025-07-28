# backend.tf
# This file tells Terraform how to store its state remotely.
# IMPORTANT: You need to run `terraform init` twice:
# 1. With this block commented out (to create the S3 bucket and DynamoDB table)
# 2. With this block uncommented (to tell Terraform to use them for state)
# Or, you can manually create the S3 bucket and DynamoDB table first.

/* terraform {
  backend "s3" {
    bucket         = "shchukova-ml-data-lake-bucket-unique-name-14587976567" # e.g., ml-infra-demo-terraform-state-us-east-1-unique
    key            = "ml-infra-demo46/terraform.tfstate"
    region         = "us-east-2" # Must match your var.aws_region
    dynamodb_table = "CHANGE_ME_TO_YOUR_DYNAMODB_TABLE_FOR_LOCKING" # e.g., ml-infra-demo-terraform-state-lock
    encrypt        = true
  }
}
*/