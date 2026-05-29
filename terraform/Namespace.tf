# 1. Khởi tạo Namespace Cô Lập bằng Terraform
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

# 2. Cấu hình Resource Quota giới hạn tài nguyên cho Namespace trên
resource "kubernetes_resource_quota" "staging_quota" {
  depends_on = [kubernetes_namespace.isolated_namespace] # Chỉ tạo sau khi Namespace đã có sẵn

  metadata {
    name      = "${var.K8S_NAMESPACE}-quota"
    namespace = kubernetes_namespace.isolated_namespace.metadata[0].name
  }

  spec {
    hard = {
      "pods"           = "5"      # Tối đa 5 Pod được chạy trong namespace này
      "requests.cpu"    = "1"      # Tổng lượng CPU yêu cầu tối đa là 1 Core (1000m)
      "requests.memory" = "1Gi"    # Tổng lượng RAM yêu cầu tối đa là 1 Gigabyte
      "limits.cpu"      = "2"      # Ngưỡng CPU tối đa có thể burst là 2 Cores
      "limits.memory"   = "2Gi"    # Ngưỡng RAM tối đa có thể vọt lên là 2 Gigabytes
    }
  }
}