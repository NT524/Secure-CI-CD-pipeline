# --- 1. KHAI BÁO BIẾN (Nếu chưa để ở file variables.tf thì để ở đây) ---
variable "ghcr_pat" {}
variable "app_image" {}

# --- 2. CẤU HÌNH PROVIDER ---
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  # config_path    = "~/.kube/config"
  # config_context = "minikube"
}

# --- 3. TẠO NAMESPACE (Giữ 1 cái duy nhất) ---
resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging-env"
  }
}

# --- 4. TẠO SECRET ĐỂ PULL IMAGE (Giữ 1 cái duy nhất) ---
resource "kubernetes_secret" "ghct_secret" {
  metadata {
    name      = "ghcr-secret"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          auth = base64encode("username:${var.ghcr_pat}")
        }
      }
    })
  }
}

# --- 5. DEPLOYMENT & SERVICE CHO DATABASE (MONGODB) ---
resource "kubernetes_deployment" "mongo_deploy" {
  metadata {
    name      = "mongo"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    selector { match_labels = { app = "mongo" } }
    template {
      metadata { labels = { app = "mongo" } }
      spec {
        container {
          name  = "mongo"
          image = "mongo:4.4"
          port { container_port = 27017 }
        }
      }
    }
  }
}

resource "kubernetes_service" "mongo_service" {
  metadata {
    name      = "mongo"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    selector = { app = "mongo" }
    port {
      port = 27017
      target_port = 27017
    }
  }
}

# --- 6. DEPLOYMENT & SERVICE CHO WEB APP (NODEGOAT) ---
resource "kubernetes_deployment" "nodegoat" {
  metadata {
    name      = "nodegoat-app"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    replicas = 3
    selector { match_labels = { app = "nodegoat" } }
    template {
      metadata { labels = { app = "nodegoat" } }
      spec {
        image_pull_secrets {
          name = kubernetes_secret.ghct_secret.metadata[0].name
        }
        container {
          name  = "nodegoat"
          image = var.app_image # Nhận image từ CI
          image_pull_policy = "IfNotPresent"

          security_context {
            run_as_non_root = true
            allow_privilege_escalation = false
          }
          command = ["sh", "-c", "until nc -z -w 2 mongo 27017 && echo 'mongo is ready' && node artifacts/db-reset.js && npm start; do sleep 2; done"]
          port { container_port = 4000 }
          env {
            name  = "MONGODB_URI"
            value = "mongodb://mongo:27017/nodegoat"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app_service" {
  metadata {
    name      = "nodegoat-service"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    selector = { app = "nodegoat" }
    type     = "NodePort"
    port {
      port      = 4000
      node_port = 30080
    }
  }
}
