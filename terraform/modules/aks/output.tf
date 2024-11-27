output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
}

output "kube_admin_config_raw" {
  value     = azurerm_kubernetes_cluster.aks.kube_admin_config_raw
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config
  sensitive = true
}

output "kubelet_identity_principal_id" {
  value = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "identity_principal_id" {
  value = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}

output "aks_ec2_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "key_vault" {
  value     = azurerm_key_vault.key_vault
}

output "key_vault_secret_kubeconfig" {
  value     = azurerm_key_vault_secret.kubeconfig
}