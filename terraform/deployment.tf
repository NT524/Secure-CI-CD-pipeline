resource "kubernetes_manifest" "nodegoat_deploy" {
  manifest = yamldecode(templatefile("${path.module}/../k8s/", {
    app_image = var.app_image
  }))
}