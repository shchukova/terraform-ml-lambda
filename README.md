# AWS ML Infrastructure Deployment with Terraform

This project provides a comprehensive guide and Terraform configuration to deploy a foundational Machine Learning (ML) infrastructure on AWS. It sets up an S3 data lake, an EC2 instance for ML processing, and a serverless API endpoint using Lambda and API Gateway for model inference. The workflow emphasizes best practices like remote state management with S3 and DynamoDB for team collaboration and state locking.

---

## Features

* **S3 Data Lake:** A dedicated S3 bucket (`ml-data-lake`) for storing raw and processed ML data.
* **EC2 ML Server:** An EC2 instance configured to act as an ML processing server, with network access to the S3 data lake.
* **Serverless Inference API:** An AWS Lambda function integrated with API Gateway to provide a scalable and cost-effective endpoint for real-time model predictions.
* **Terraform for Infrastructure as Code:** Automates the provisioning and management of all AWS resources, ensuring reproducibility and version control.
* **Remote State Management:** Configures Terraform to store its state in an S3 bucket and use DynamoDB for state locking, crucial for collaborative environments and preventing concurrent modifications.

---

## Prerequisites

Before you begin, ensure you have the following installed and configured:

* **Terraform:** [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
* **AWS CLI:** [Install and configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
* **An AWS Account:** With appropriate permissions to create EC2 instances, S3 buckets, Lambda functions, API Gateways, and DynamoDB tables.

---

## Execution Steps
Follow these steps to deploy and verify your AWS ML infrastructure.

### 1. Clone/Create Project

Set up your project directory structure and populate it with your Terraform files (e.g., `main.tf`, `variables.tf`, `outputs.tf`, `backend.tf`).

### 2. AWS Credentials

Ensure your AWS CLI is configured with the necessary credentials. You can do this by running:

```bash
aws configure

```

### 3.  Create SSH Key Pair (if you don't have one)
This key pair will be used to SSH into your EC2 instance.

* Go to the AWS Console -> EC2 -> Key Pairs.

* Click Create key pair.

* Name it (e.g., my-ml-key) and download the .pem file.

* Crucially, update the aws_instance.ml_server's key_name argument in your Terraform configuration with this exact name.

### 4. Backend Setup (if using remote state)
This step initializes your remote state management using S3 for storage and DynamoDB for locking.

* Initially, comment out the backend block in your backend.tf file.

* Run terraform init to initialize the local Terraform configuration.

* Run terraform apply to create the S3 state bucket and DynamoDB lock table. Confirm with yes when prompted.

* Once applied, uncomment the backend block in backend.tf and update the bucket and dynamodb_table values with the names of the resources Terraform just created.

* Run terraform init again. Terraform will detect the backend change and prompt to migrate local state to the remote backend. Confirm with yes.

###  5. Main Deployment
Now, deploy the core ML infrastructure.

* Open your terminal in the project root directory.

* Run terraform init (if you haven't already, or after the backend change).

* Run terraform plan to see what resources Terraform will create. Review carefully!

* Run terraform apply. Type yes when prompted.

* Wait for the deployment to complete (this may take a few minutes for EC2, Lambda, and API Gateway).

### 6. Verification
After the deployment, verify that all resources are correctly provisioned and functional.

* Check outputs.tf values in your terminal. These will provide important information like your EC2 public IP and API Gateway invoke URL.

* S3: Go to the AWS S3 console and verify your ml-data-lake bucket exists.

* EC2: SSH into your EC2 instance using the public IP from outputs.tf:

```bash

ssh -i /path/to/your/ssh-key.pem ubuntu@<EC2_PUBLIC_IP>
Once connected, you should be able to list S3 buckets from here using:

```

```bash
aws s3 ls
Lambda/API Gateway: Use curl or Postman to test your API Gateway endpoint:
```

```bash
curl -X POST -H "Content-Type: application/json" -d '{"data": "hello terraform"}' <YOUR_API_GATEWAY_INVOKE_URL>/your/path
```

Example:


```bash

curl -X POST -H "Content-Type: application/json" -d '{"data": "hello terraform"}' [https://xxxx.execute-api.us-east-1.amazonaws.com/v1/anything](https://xxxx.execute-api.us-east-1.amazonaws.com/v1/anything)
```
You should receive a JSON response similar to: {"prediction": "Received: 'hello terraform' - This is a dummy prediction from Lambda!"}.

### 7. Clean Up
*VERY IMPORTANT:* To avoid incurring unnecessary AWS charges, destroy all resources when you are finished.

Run terraform destroy. Type yes when prompted.

