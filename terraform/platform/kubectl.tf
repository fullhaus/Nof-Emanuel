# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key             = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
}

# Deployment for Application
resource "kubernetes_deployment" "nof_emanuel_app_deployment" {
  metadata {
    name      = "${local.env}-${local.config["project"]}-app-nof-emanuel"
    namespace = "default"
    labels = {
      app = "nof-emanuel-app"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nof-emanuel-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "nof-emanuel-app"
        }
      }

      spec {
        container {
          name  = "nof-emanuel-app"
          image = "nofemanueltest.azurecr.io/app:latest"
          port {
            container_port = 3000
          }
          resources {
            limits = {
              cpu    = "200m"
              memory = "128Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "64Mi"
            }
          }
        }
      }
    }
  }
}

# Service for Application
resource "kubernetes_service" "nof_emanuel_app_service" {
  metadata {
    name      = "${local.env}-${local.config["project"]}-nof-emanuel-service"
    namespace = "default"
    labels = {
      app = "nof-emanuel-app"
    }
  }

  spec {
    selector = {
      app = "nof-emanuel-app"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "NodePort"
  }
}

# HPA for Application
resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  metadata {
    name      = "${local.env}-${local.config["project"]}-app-hpa"
    namespace = "default"
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = "nof-emanuel-app"
    }

    min_replicas = 1
    max_replicas = 5

    metric {
      type = "Resource"
      resource {
        name  = "cpu"
        target {
          type    = "Utilization"
          average_utilization = 50
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name  = "memory"
        target {
          type    = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}