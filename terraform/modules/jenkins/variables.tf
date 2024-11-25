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

variable "vnet_jenkins_subnet_id" {
  description = "The id of the subnet for Jenkins"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}