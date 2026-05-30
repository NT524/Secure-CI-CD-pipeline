resource "kubernetes_namespace" "isolated_namespace" {
  depends_on = [module.eks, module.vpc] # Chỉ tạo sau khi cụm EKS và VPC đã dựng xong thành công

  metadata {
    name = var.K8S_NAMESPACE

    labels = {
      environment = var.environment
      tier        = "isolated-staging"
      managed-by  = "terraform"
    }
  }
}
