variable "resource_group_name" {
  description = "Default resource group name that the network will be created in."
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
}

variable "environment" {
  type        = string
  description = "Environment short name"
}

variable "project" {
  type        = string
  default     = "finray"
  description = "Project name"
}

variable "node_resource_group" {
  type        = string
  description = "The auto-generated Resource Group which contains the resources for this Managed Kubernetes Cluster. Changing this forces a new resource to be created."
  default     = null
}

variable "vnet_subnet_id" {}
variable "node_count" {}
variable "os_disk_size_gb" {}
variable "aks_version" {}
variable "vm_size" {}

variable "ad_group_member" {}
variable "admin_username" {}
