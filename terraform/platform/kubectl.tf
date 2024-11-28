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

# Secret azure-dns-credentials
resource "kubernetes_secret" "azure_dns_credentials" {
  metadata {
    name      = "azure-dns-credentials"
    namespace = "ingress-basic"
  }

  data = {
    # Encode your client secret in base64 for Kubernetes compatibility
    "client-secret" = azuread_application_password.external_dns_secret.value
  }
}

# ClusterIssuer
resource "kubernetes_manifest" "letsencrypt_cluster_issuer" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-${local.env}"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "Vasyl@2bcloudsandbox.onmicrosoft.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-${local.env}"
        }
        "solvers" = [
          {
            "dns01" = {
              "azureDNS" = {
                "clientID"     = data.azuread_application.test.client_id
                "clientSecretSecretRef" = {
                  "name" = "azure-dns-credentials"
                  "key"  = "client-secret"
                }
                "tenantID" = data.azurerm_client_config.current.tenant_id
                "subscriptionID" = data.azurerm_client_config.current.subscription_id
                "resourceGroupName" = local.config["resource_group_name"]
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress,
    helm_release.external_dns
  ]
}

# Ingress
resource "kubernetes_ingress_v1" "example" {
  metadata {
    name      = "${local.env}-${local.config["project"]}-nof-emanuel-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"                 = "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect"    = "false"
      "cert-manager.io/cluster-issuer"              = "letsencrypt-${local.env}"
      "nginx.ingress.kubernetes.io/rewrite-target"  = "/"
      "external-dns.alpha.kubernetes.io/hostname"   = "web.nof-emanuel.local"
    }
  }

  spec {
    rule {
      host = "web.nof-emanuel.local"
      http {
        path {
          path     = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "${local.env}-${local.config["project"]}-nof-emanuel-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts      = ["web.nof-emanuel.local"]
      secret_name = "web-${local.env}-${local.config["project"]}-app-tls"
    }
  }

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress,
    helm_release.external_dns
  ]
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