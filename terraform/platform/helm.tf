# Helm Provider Configuration
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.0.host
    client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
    client_key             = base64decode(module.aks.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
  }
}

# NGINX Ingress Controller with Static IP
resource "azurerm_public_ip" "nginx_ingress" {
  name                = "${local.env}-${local.config["project"]}-nginx-ingress"
  resource_group_name = "${local.config["resource_group_name"]}-${local.env}-aks"
  location            = local.config["location"]
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Namespace for NGINX Ingress Controller
resource "kubernetes_namespace" "nginx_namespace" {
  metadata {
    name = "ingress-basic"

    labels = {
      "cert-manager.io/disable-validation" = "true"
    }
  }
}

# NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  namespace  = "ingress-basic"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  version    = "4.11.3"

  values = [
    <<EOT
controller:
  replicaCount: 2
  nodeSelector:
    kubernetes.io/os: linux
  service:
    externalTrafficPolicy: Local
    loadBalancerIP: "${azurerm_public_ip.nginx_ingress.ip_address}"

defaultBackend:
  nodeSelector:
    kubernetes.io/os: linux
EOT
  ]

  depends_on = [kubernetes_namespace.nginx_namespace]
}

# Cert Manager Helm Chart
resource "helm_release" "cert_manager" {
  name             = "${local.env}-${local.config["project"]}-cert-manager"
  namespace        = "ingress-basic"
  create_namespace = true
  #
  chart      = "cert-manager"
  repository = "https://charts.jetstack.io"
  version    = "1.10.0"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "azurerm_dns_zone" "dns_zone" {
  name                = "nof-emanuel.io"
  resource_group_name = local.config["resource_group_name"]
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = "${local.env}-${local.config["project"]}-identity"
  resource_group_name = local.config["resource_group_name"]
  location            = local.config["location"]
}

data "azurerm_resource_group" "id" {
  name = local.config["resource_group_name"]
}

resource "azurerm_role_assignment" "dns_contributor" {
  #scope                = data.azurerm_resource_group.id.id
  scope                = azurerm_dns_zone.dns_zone.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

# Define the Azure Active Directory Application
resource "azuread_application" "external_dns_app" {
  display_name = "external-dns-sp"
}

resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns"
    namespace = "kube-system"
  }

  data = {
    "azure.json" = jsonencode({
      "cloud": "AzurePublicCloud",
      "tenantId": "bd4f0481-b137-40f1-9e64-20cfd55fbf49",
      "aadClientId": "b8a4491a-373f-4394-a95f-57b63259c9fd",
      "aadClientSecret": "A9v8Q~fXljgNWUCchhItCPyNmLTTiFau8PwzRb74",
      "subscriptionId": "2fa0e512-f70e-430f-9186-1b06543a848e",
      "resourceGroup": local.config["resource_group_name"],
      "userAssignedIdentityClientID": azurerm_user_assigned_identity.identity.client_id,
      "useManagedIdentityExtension": true
    })
  }
}

# External DNS Helm Chart
resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "external-dns"
  version    = "8.6.0"

  set {
    name  = "provider"
    value = "azure"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "txtOwnerId"
    value = "${local.config["project"]}-${local.env}-aks"
  }

  set {
    name  = "azure.secretName"
    value = "external-dns"
  }

  depends_on = [
    helm_release.cert_manager,
    kubernetes_secret.external_dns
  ]
}

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