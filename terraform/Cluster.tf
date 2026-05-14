resource "kind_cluster" "nodegoat" {
  name           = var.cluster_name
  node_image     = "kindest/node:v1.27.3" # Bạn có thể chọn version K8s
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
    }
  }
}

# Đảm bảo các tài nguyên khác (Namespace, Image Load) phải đợi Cluster xong
resource "kubernetes_namespace" "nodegoat_staging" {
  metadata {
    name = "nodegoat-staging"
  }
  depends_on = [kind_cluster.nodegoat]
}