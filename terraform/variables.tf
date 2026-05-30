variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "ARN_IAM_USER" {
  description = "ARN of the IAM User or Role that GitHub Actions will use for authentication"
  type        = string
}
variable "ARN_POLICY" {
  description = "ARN of the IAM Policy to associate with the GitHub Actions principal for cluster access"
  type        = string
}

variable "IMAGE_NAME" {
  description = "Docker image for the application to deploy on EKS"
  type        = string
}

variable "K8S_NAMESPACE" {
  description = "Kubernetes namespace to deploy the application"
  type        = string
}

variable "AWS_ACCESS_KEY_ID" {
  description = "AWS Access Key ID for GitHub Actions"
  type        = string
  sensitive   = true
}
variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS Secret Access Key for GitHub Actions"
  type        = string
  sensitive   = true
}
