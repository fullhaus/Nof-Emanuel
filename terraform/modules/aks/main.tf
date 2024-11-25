# Data sources for current Azure details
data "azurerm_client_config" "current" {}

# Create a Key Vault to store SSH keys
resource "azurerm_key_vault" "key_vault" {
  name                        = "${var.environment}-aks-vau"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "Set", "Delete", "List"]
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.environment}-aks-dns"
  node_resource_group = var.node_resource_group
  kubernetes_version  = var.aks_version
  #
  http_application_routing_enabled = true
  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  web_app_routing {
    dns_zone_id = ""
  }

  default_node_pool {
    name                 = "default"
    zones                = [1, 2, 3]
    node_count           = var.node_count
    orchestrator_version = var.aks_version
    os_disk_size_gb      = var.os_disk_size_gb
    vm_size              = var.vm_size
    max_pods             = 250
    vnet_subnet_id       = var.vnet_subnet_id
    #
    temporary_name_for_rotation = "defaulttemp"
    #
    upgrade_settings {
      max_surge = 50
      node_soak_duration_in_minutes = 0
    }
  }

  identity { type = "SystemAssigned" }

  role_based_access_control_enabled = true

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = "10.2.0.10"
    service_cidr       = "10.2.0.0/22"
    load_balancer_sku  = "standard"
  }

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      key_data = tls_private_key.ssh.public_key_openssh
    }
  }

  lifecycle {
    ignore_changes = [
      web_app_routing.0.dns_zone_id
    ]
  }

  tags = {
    Environment = var.environment
    Product     = var.project
  }
}

resource "azurerm_role_assignment" "aks_admin_rbac" {
  principal_id         = azuread_group.aks_admins.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  scope                = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_key_vault_secret" "kubeconfig" {
  name         = "${var.project}-${var.environment}-aks-kubeconfig"
  value        = azurerm_kubernetes_cluster.aks.kube_config_raw
  key_vault_id = azurerm_key_vault.key_vault.id
}