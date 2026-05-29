

resource "kubernetes_namespace" "isolated_namespace" {
  depends_on = [module.eks] # Chỉ tạo sau khi cụm EKS đã dựng xong thành công

  metadata {
    name = var.K8S_NAMESPACE

    labels = {
      environment = var.environment
      tier        = "isolated-staging"
      managed-by  = "terraform"
    }
  }
}
