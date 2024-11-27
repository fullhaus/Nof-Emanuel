## TODO
# kubectl edit csidriver secrets-store.csi.k8s.io
#metadata:
#  annotations:
#    meta.helm.sh/release-name: secrets-store-csi-driver
#    meta.helm.sh/release-namespace: kube-system
#  labels:
#    app.kubernetes.io/managed-by: Helm

# resource "kubernetes_manifest" "csi_driver_annotations" {
#   manifest = {
#     "apiVersion" = "storage.k8s.io/v1"
#     "kind"       = "CSIDriver"
#     "metadata" = {
#       "name" = "secrets-store.csi.k8s.io"
#       "annotations" = {
#         "meta.helm.sh/release-name"      = "secrets-store-csi-driver"
#         "meta.helm.sh/release-namespace" = "kube-system"
#       }
#       "labels" = {
#         "app.kubernetes.io/managed-by" = "Helm"
#       }
#     }
#   }
# }

resource "helm_release" "csi_driver" {
  name       = "secrets-store-csi-driver"
  chart      = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  namespace  = "kube-system"

  set {
    name  = "csiDriver.create"
    value = "false"
  }
  #depends_on = [kubernetes_manifest.csi_driver_annotations]
}

data "azurerm_client_config" "current" {}

resource "kubernetes_manifest" "keyvault_provider" {
  manifest = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = "azure-keyvault"
      namespace = "default"
    }
    spec = {
      provider = "azure"
      parameters = {
        usePodIdentity       = "false"
        useVMManagedIdentity = "true"
        keyvaultName         = module.aks.key_vault.name
        objects              = "[{objectName: \"${module.aks.key_vault_secret_kubeconfig.name}\", objectType: \"secret\"}]"
        tenantId             = data.azurerm_client_config.current.tenant_id
      }
    }
  }

  depends_on = [helm_release.csi_driver]
}