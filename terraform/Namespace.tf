resource "kubernetes_namespace" "isolated_namespace" {
  depends_on = [module.eks] 

  metadata {
    name = var.K8S_NAMESPACE

    labels = {
      environment = var.environment
      tier        = "isolated-staging"
      managed-by  = "terraform"
    }
  }
}
