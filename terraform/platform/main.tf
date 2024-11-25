module "network" {
  source = "../modules/network"
  #
  resource_group_name = local.config["resource_group_name"]
  environment         = local.env
  project             = local.config["project"]
  location            = local.config["location"]
  address_space       = "10.1.0.0/16"
  subnet_prefixes     = ["10.1.0.0/20", "10.1.16.0/24"]
  subnet_names        = ["aks-subnet", "jenkins-subnet"]
}

module "jenkins" {
  source = "../modules/jenkins"
  #
  resource_group_name    = local.config["resource_group_name"]
  location               = local.config["location"]
  environment            = local.env
  project                = local.config["project"]
  vnet_jenkins_subnet_id = module.network.vnet_aks_subnet_ids["jenkins-subnet"]
  admin_username         = "azureuser"
}

module "container-registry" {
  source = "../modules/container-registry"
  #
  resource_group_name = local.config["resource_group_name"]
  location            = local.config["location"]
  environment         = local.env
  project             = "nofemanuel"
}

module "aks" {
  source = "../modules/aks"
  #
  resource_group_name = local.config["resource_group_name"]
  location            = local.config["location"]
  environment         = local.env
  project             = local.config["project"]
  node_resource_group = "${local.config["resource_group_name"]}-${local.env}-aks"
  aks_version         = "1.30.3"
  node_count          = "1"
  vm_size             = "Standard_D4s_v4"
  os_disk_size_gb     = "128"
  vnet_subnet_id      = module.network.vnet_aks_subnet_ids["aks-subnet"]
  admin_username      = "${local.config["project"]}-admin"
  ad_group_member     = ["64a48119-e958-4d3c-ae0a-05de048b3775"]
}

# resource "azurerm_role_assignment" "registry" {
#   principal_id                     = module.aks.kubelet_identity_principal_id
#   role_definition_name             = "AcrPull"
#   scope                            = module.container-registry.acr_id
#   skip_service_principal_aad_check = true
# }
