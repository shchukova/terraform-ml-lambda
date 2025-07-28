# terraform-ml-lambda
Terraform Project for ML Engineers (AWS)
S3 Data Lake & Basic Serverless ML Inference Setup
This project will demonstrate how to provision the core infrastructure for an ML workflow: data storage, a compute environment, and a simple serverless inference endpoint.
Goal:
Provision an S3 bucket: To act as your "data lake" for raw data and model artifacts.
Set up an EC2 instance: A basic VM for model training/experimentation (or even just simulating it).
Deploy a Serverless Inference Endpoint (Lambda + API Gateway): To simulate deploying a simple ML model for real-time predictions.

Execution Steps (The Weekend Workflow)
Clone/Create Project: Set up the directory structure and files as described above.
AWS Credentials: Ensure your AWS CLI is configured (aws configure).
Create SSH Key Pair (if you don't have one):
Go to AWS Console -> EC2 -> Key Pairs -> Create key pair.
Name it (e.g., my-ml-key) and download the .pem file.
Crucially, update aws_instance.ml_server's key_name argument with this exact name.
Backend Setup (if using remote state):
Initially, comment out the backend block in backend.tf.
Run terraform init.
Run terraform apply (to create the S3 state bucket and DynamoDB lock table). Confirm with yes.
Once applied, uncomment the backend block in backend.tf and update bucket and dynamodb_table values with the names of the resources Terraform just created.
Run terraform init again. Terraform will detect the backend change and prompt to migrate local state to the remote backend. Confirm with yes.
Main Deployment:
Open your terminal in the project root.
Run terraform init (if you haven't already, or after backend change).
Run terraform plan to see what resources Terraform will create. Review carefully!
Run terraform apply. Type yes when prompted.
Wait for the deployment to complete (may take a few minutes for EC2, Lambda, API Gateway).
Verification:
Check the outputs.tf values in your terminal.
S3: Go to the AWS S3 console and verify your ml-data-lake bucket exists.
EC2: SSH into your EC2 instance using the public IP from outputs: ssh -i /path/to/your/ssh-key.pem ubuntu@<EC2_PUBLIC_IP>. You should be able to list S3 buckets from here using aws s3 ls.
