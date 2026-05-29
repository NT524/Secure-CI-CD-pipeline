terraform {
  required_version = ">=1.5.0"

    backend "s3" {
        # bucket         = S3_BUCKET
        # key            = S3_KEY
        # region         = S3_REGION
        # encrypt        = true
        # dynamodb_table = DYNAMODB_TABLE
    }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"

    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "juice-shop-eks"
      Manager     = "Terraform"
    }
  }
}
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # Tự động lấy token bảo mật tạm thời từ cụm EKS vừa tạo
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}
