# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

# # NGINX Ingress Controller with Static IP
# resource "azurerm_public_ip" "nginx_ingress" {
#   name                = "${local.env}-${local.config["project"]}-ginx-ingress"
#   resource_group_name = local.config["resource_group_name"]
#   location            = local.config["location"]
#   allocation_method   = "Static"
# }

# # Namespace for NGINX Ingress Controller
# resource "kubernetes_namespace" "nginx_namespace" {
#   metadata {
#     name = "ingress-basic"

#     labels = {
#       "cert-manager.io/disable-validation" = "true"
#     }
#   }
# }

# # NGINX Ingress Controller
# resource "helm_release" "nginx_ingress" {
#   name       = "ingress-nginx"
#   namespace  = "ingress-basic"
#   chart      = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   version    = "4.11.3"

#   values = [
#     <<EOT
# controller:
#   replicaCount: 2
#   nodeSelector:
#     kubernetes.io/os: linux
#   service:
#     externalTrafficPolicy: Local
#     loadBalancerIP: "${azurerm_public_ip.nginx_ingress.ip_address}"

# defaultBackend:
#   nodeSelector:
#     kubernetes.io/os: linux
# EOT
#   ]

#   depends_on = [kubernetes_namespace.nginx_namespace]
# }

# Cert Manager Helm Chart
# resource "helm_release" "cert_manager" {
#   name       = "${local.env}-${local.config["project"]}-cert-manager"
#   namespace  = "ingress-basic"
#   create_namespace = true
#   chart      = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   version    = "1.10.0"

#   set {
#     name  = "installCRDs"
#     value = "true"
#   }
# }

# External DNS Helm Chart
# resource "helm_release" "external_dns" {
#   name       = "${local.env}-${local.config["project"]}-external-dns"
#   namespace  = "kube-system"
#   chart      = "external-dns"
#   repository = "https://charts.bitnami.com/bitnami"
#   version    = "6.32.0"

#   set {
#     name  = "azure.secretName"
#     value = "external-dns-secret"
#   }
# }

# Namespace for redis
resource "kubernetes_namespace" "redis_namespace" {
  metadata {
    name = "${local.env}-${local.config["project"]}-redis"
  }
}

# Redis Sentinel Installation
resource "helm_release" "redis_sentinel" {
  name       = "${local.env}-${local.config["project"]}-redis"
  namespace  = "${local.env}-${local.config["project"]}-redis"
  chart      = "redis"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "17.3.11"

  set {
    name  = "architecture"
    value = "replication"
  }

  set {
    name  = "replica.replicaCount"
    value = "2"
  }

  depends_on = [kubernetes_namespace.redis_namespace]
}