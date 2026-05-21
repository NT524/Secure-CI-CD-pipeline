terraform {
  required_providers {
    kubernetes = {
        source = "hashicorp/kubernetes"
        version = ">= 2.23.0"
    }

    kind = {
      source  = "tehcyx/kind"
      version = "0.6.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

provider "kubernetes" {
  # config_path = "~/.kube/config"
}
