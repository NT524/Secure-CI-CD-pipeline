resource "kubernetes_manifest" "nodegoat_deploy" {
  # Lấy danh sách tất cả file .yaml trong thư mục k8s
  for_each = fileset("${path.module}/../k8s", "*.yaml")

  manifest = yamldecode(templatefile("${path.module}/../k8s/${each.value}", {
    app_image = var.app_image
  }))

  # Đảm bảo cluster và namespace có trước khi apply manifest
  depends_on = [kubernetes_namespace.nodegoat_staging, kind_cluster.nodegoat]
}