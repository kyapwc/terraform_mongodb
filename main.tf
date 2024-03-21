variable "mongodb_database_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1100m",
      memory = "800Mi"
    }
    requests = {
      cpu    = "200m",
      memory = "80Mi"
    }
  }
}

variable "mongodb_operator_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "800m",
      memory = "600Mi"
    }
    requests = {
      cpu    = "80m",
      memory = "60Mi"
    }
  }
}

resource "kubernetes_secret" "mongodb_user_pass" {
  metadata {
    name      = "mongodb-user-password"
    namespace = "mongodb"
  }
  data = {
    password = "pickuppdev2024"
  }
  type = "Opaque"
}

resource "kubernetes_secret" "mongodb_admin_pass" {
  metadata {
    name      = "mongodb-admin-password"
    namespace = "mongodb"
  }
  data = {
    password = "pickuppdev2024"
  }
  type = "Opaque"
}

resource "helm_release" "mongodb-operator" {
  name             = "mongodb-operator"
  namespace        = "mongodb"
  create_namespace = true
  reuse_values     = false

  repository = "https://mongodb.github.io/helm-charts"
  chart      = "community-operator"

  values = ["${file("mongodb_operator_values.yaml")}"]

  set {
    name  = "operator.resources.limits.cpu"
    value = var.mongodb_operator_resources.limits.cpu
  }

  set {
    name  = "operator.resources.limits.memory"
    value = var.mongodb_operator_resources.limits.memory
  }

  set {
    name  = "operator.resources.requests.cpu"
    value = var.mongodb_operator_resources.requests.cpu
  }

  set {
    name  = "operator.resources.requests.memory"
    value = var.mongodb_operator_resources.requests.memory
  }
}

locals {
  mongodb_manifest_content = templatefile("mongodb_values.yaml", {
    cpu_limits = var.mongodb_database_resources.limits.cpu
    memory_limits = var.mongodb_database_resources.limits.memory
    cpu_requests = var.mongodb_database_resources.requests.cpu
    memory_requests = var.mongodb_database_resources.requests.memory
  })
}

resource "kubernetes_manifest" "mongodb_community" {
  manifest = yamldecode(local.mongodb_manifest_content)
  depends_on = [helm_release.mongodb-operator]
}
