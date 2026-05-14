# Create a Kubernetes namespace for the NodeGoat staging environment
resource "kubernetes_namespace" "nodegoat_staging" {
  metadata {
    name = var.k8s_namespace
    labels ={
        environment = "staging"
        app         = "nodegoat"
        "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}