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


variable "S3_BUCKET" {
  description = "The name of the S3 bucket for Terraform state storage"
  type        = string
}

variable "S3_REGION" {
  description = "The AWS region where the S3 bucket is located"
  type        = string
}

variable "DYNAMODB_TABLE" {
  description = "The name of the DynamoDB table for Terraform state locking"
  type        = string
}