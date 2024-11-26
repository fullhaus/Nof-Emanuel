# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

# Cert Manager Helm Chart
resource "helm_release" "cert_manager" {
  name       = "${local.env}-${local.config["project"]}-cert-manager"
  namespace  = "${local.env}-${local.config["project"]}-cert-manager"
  create_namespace = true
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "1.10.0"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

# # External DNS Helm Chart
# resource "helm_release" "external_dns" {
#   name       = "${local.env}-${local.config["project"]}-external-dns"
#   namespace  = "${local.env}-${local.config["project"]}-kube-system"
#   chart      = "external-dns"
#   repository = "https://kubernetes-charts.storage.googleapis.com/"
#   version    = "1.10.0"

#   set {
#     name  = "azure.secretName"
#     value = "external-dns-secret"
#   }
# }

# # NGINX Ingress Controller
# resource "helm_release" "nginx_ingress" {
#   name       = "${local.env}-${local.config["project"]}-nginx-ingress"
#   namespace  = "${local.env}-${local.config["project"]}-nginx-ingress"
#   chart      = "ingress-nginx"
#   repository = "https://kubernetes.github.io/ingress-nginx"
#   version    = "4.7.1"

#   set {
#     name  = "controller.service.loadBalancerIP"
#     value = azurerm_public_ip.nginx_ingress.ip_address
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