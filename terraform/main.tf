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

  name = "juice-shop-vpc-${random_string.suffix.result}"
  cidr = lookup(local.vpc_dirs, var.environment)


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
      instance_types = [lookup(local.instance_types, var.environment)]

      min_size     = 1
      max_size     = 3
      desired_size = lookup(local.desired_instances, var.environment)

      #   block_device_mappings = {
      #     xvda = {
      #       device_name = "/dev/xvda"
      #       ebs = {
      #         volume_size = 50
      #         volume_type = "gp3"
      #         encrypted   = true
      #       }
      #     }
      #   }
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
      # Thay bằng ARN của IAM User hoặc Role mà GitHub Actions đang dùng
      principal_arn     = var.ARN_IAM_USER 
      
      policy_associations = {
        cluster_admin = {
          # Cấp quyền Admin trên toàn bộ Cluster
          policy_arn = var.ARN_POLICY
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

}

# Resource này dùng để kích hoạt Ansible sau khi EKS tạo xong
resource "null_resource" "ansible_deploy" {
  # Đảm bảo Ansible chỉ chạy SAU KHI module EKS và các Node Group đã hoàn thành
  depends_on = [module.eks]

  # Trigger này giúp tái kích hoạt Ansible nếu thông tin Image hoặc Namespace thay đổi
  triggers = {
    app_image     = var.IMAGE_NAME # Hoặc biến chứa link ảnh Docker của bạn
    k8s_namespace = var.K8S_NAMESPACE
    always_run    = timestamp() # Bỏ comment dòng này nếu muốn LẦN NÀO terraform apply cũng chạy lại Ansible
  }

  provisioner "local-exec" {
    # Khai báo các biến môi trường trực tiếp cho script chạy
    environment = {
      AWS_ACCESS_KEY_ID     = var.AWS_ACCESS_KEY_ID
      AWS_SECRET_ACCESS_KEY = var.AWS_SECRET_ACCESS_KEY
      AWS_DEFAULT_REGION    = var.aws_region
      CLUSTER_NAME          = "${local.cluster_name}"
    }

    # Lệnh thực thi chạy Playbook
    command = <<EOT
      echo "=== [Terraform Local-Exec] Đang cấu hình Kubeconfig ==="
      aws eks update-kubeconfig --region $AWS_DEFAULT_REGION --name $CLUSTER_NAME


      echo "=== [Terraform Local-Exec] Bắt đầu kích hoạt Ansible Playbook ==="
      ansible-playbook ${path.cwd}/../ansible/playbooks/deploy-k8s.yml \
        -i ${path.cwd}/../ansible/inventory.ini \
        -e "tf_var_k8s_namespace=${var.K8S_NAMESPACE}" \
        -e "tf_var_image_name=${var.IMAGE_NAME}" \
        -e "tf_var_GITHUB_TOKEN=${var.GITHUB_TOKEN}" \
        -e "tf_var_GITHUB_ACTOR=${var.GITHUB_ACTOR}" \

    EOT
  }
}

# data "kubernetes_service" "juice_shop" {
#   depends_on = [null_resource.ansible_deploy]
#   metadata {
#     name      = "juice-shop"
#     namespace = var.K8S_NAMESPACE
#   }
# }


