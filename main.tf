provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "ml_data_lake" {
  bucket = "${var.s3_bucket_name}-${var.aws_region}" # Append region for more uniqueness, though it still needs to be globally unique
  tags = {
    Name        = "${var.project_name_prefix}-data-lake"
    Environment = "Dev"
    Project     = "MLInterview"
  }
}

resource "aws_s3_bucket_acl" "ml_data_lake_acl" {
  bucket = aws_s3_bucket.ml_data_lake.id
  acl    = "private" # Best practice
}

resource "aws_s3_bucket_versioning" "ml_data_lake_versioning" {
  bucket = aws_s3_bucket.ml_data_lake.id
  versioning_configuration {
    status = "Enabled" # Good for data integrity
  }
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "${var.project_name_prefix}-terraform-state-${var.aws_region}" # Globally unique
  
  tags = {
    Name        = "${var.project_name_prefix}-terraform-state"
    Environment = "Dev"
    Project     = "MLInterview"
  }
}

resource "aws_s3_bucket_acl" "terraform_state_bucket_acl" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  acl    = "private" # Best practice
}


resource "aws_s3_bucket_versioning" "terraform_state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "${var.project_name_prefix}-terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST" # Cost-effective for infrequent use
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}


# Lambda IAM Role
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name_prefix}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "${var.project_name_prefix}-lambda-exec-role"
  }
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution_attachment"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  roles      = [aws_iam_role.lambda_exec_role.name]
}


# AWS Lambda Function

data "archive_file" "ml_inference_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code" # Path to the directory containing your Lambda code
  output_path = "lambda_code.zip"            # The name and path for the generated ZIP file
}

resource "aws_lambda_function" "ml_inference_lambda" {
  function_name    = "${var.project_name_prefix}-ml-inference-lambda"
  handler          = "main.lambda_handler" # Adjust if your main file/function name is different
  runtime          = "python3.9"          # Ensure this matches your code
  role             = aws_iam_role.lambda_exec_role.arn # Reference the ARN of your Lambda execution role

  # UPDATE THESE TWO LINES:
  filename         = data.archive_file.ml_inference_lambda_zip.output_path
  source_code_hash = data.archive_file.ml_inference_lambda_zip.output_base64sha256

  # No need for depends_on as data sources are implicitly handled
  # depends_on = [data.archive_file.ml_inference_lambda_zip] # This line is NOT needed

  tags = {
    Name = "${var.project_name_prefix}-ml-inference-lambda"
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "ml_api_gateway" {
  name        = "${var.project_name_prefix}-ml-inference-api"
  description = "API Gateway for ML Inference Lambda"
  tags = {
    Name = "${var.project_name_prefix}-ml-inference-api"
  }
}

resource "aws_api_gateway_resource" "proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.ml_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.ml_api_gateway.root_resource_id
  path_part   = "{proxy+}" # Catch-all path for flexibility
}

resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.ml_api_gateway.id
  resource_id   = aws_api_gateway_resource.proxy_resource.id
  http_method   = "ANY" # Supports GET, POST, etc.
  authorization = "NONE" # For public access demo
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.ml_api_gateway.id
  resource_id             = aws_api_gateway_resource.proxy_resource.id
  http_method             = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST" # Lambda Proxy requires POST
  type                    = "AWS_PROXY" # Enable Lambda proxy integration
  uri                     = aws_lambda_function.ml_inference_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.ml_api_gateway.id
  # Force new deployment on changes to method or integration
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy_resource.id,
      aws_api_gateway_method.proxy_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true # Deploy new version before destroying old
  }
}

resource "aws_api_gateway_stage" "api_stage" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.ml_api_gateway.id
  stage_name    = "v1"
}

# Permission for API Gateway to invoke Lambda
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ml_inference_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.ml_api_gateway.execution_arn}/*/*"
}


# IAM Role for EC2 Instance (for S3 access)
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "${var.project_name_prefix}-ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "${var.project_name_prefix}-ec2-s3-access-role"
  }
}

resource "aws_iam_policy" "s3_read_write_policy" {
  name        = "${var.project_name_prefix}-s3-read-write-policy"
  description = "Policy to allow EC2 to read/write to ML data lake S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.ml_data_lake.arn,
          "${aws_s3_bucket.ml_data_lake.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3_attach" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.s3_read_write_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

# Security Group for EC2 (SSH access)
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name_prefix}-ec2-security-group"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id # Or create a new VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: For demo only, restrict to your IP in real world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name_prefix}-ec2-sg"
  }
}

# Data Source for default VPC (simpler for quick demo)
data "aws_vpc" "default" {
  default = true
}

# EC2 Instance
resource "aws_instance" "ml_server" {
  ami           = data.aws_ami.ubuntu_lts.id # Using the data source defined earlier
  instance_type = var.instance_type
  key_name      = "your-ssh-key-name" # IMPORTANT: Replace with an existing EC2 Key Pair name!
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name        = "${var.project_name_prefix}-ml-server"
    Environment = "Dev"
    Project     = "MLInterview"
  }
}