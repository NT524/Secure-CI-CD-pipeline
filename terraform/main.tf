data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

# ✅ VPC Module - Configuring the VPC with NAT Gateway, DNS, and Subnet Tagging
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13.0"

  name = "juice-shop-vpc-${var.environment}"
  cidr = lookup(local.vpc_cidrs, var.environment)


  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = lookup(local.private_subnets, var.environment)
  public_subnets  = lookup(local.public_subnets, var.environment)

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

}


# ✅ EKS Cluster Module - Deploying an EKS Cluster with Managed Node Groups
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  vpc_id                          = module.vpc.vpc_id
  subnet_ids                      = module.vpc.private_subnets
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    vpc-cni = {
      enabled = true
    }
    coredns = {
      enabled = true
    }
    kube-proxy = {
      enabled = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type                   = "AL2023_x86_64_STANDARD"
    iam_role_attach_cni_policy = true
  }

  eks_managed_node_groups = {
    eks_nodes = {
      name           = "node-group-${var.environment}"
      instance_types = [lookup(local.instance_type, var.environment)]

      min_size     = 1
      max_size     = 3
      desired_size = lookup(local.desired_instance_count, var.environment)

      create_launch_template     = false
      use_custom_launch_template = false

      tags = {
        Environment = var.environment
        Terraform   = "true"
        Kubernetes  = "EKS"
        NodeGroup   = "managed"
      }

    }

  }

  authentication_mode = "API_AND_CONFIG_MAP"

  access_entries = {
    github_actions = {
      kubernetes_groups = []
      principal_arn     = var.ARN_IAM_USER 
      
      policy_associations = {
        cluster_admin = {
          policy_arn = var.ARN_POLICY
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

}




