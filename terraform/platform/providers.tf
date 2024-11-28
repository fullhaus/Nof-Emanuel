terraform {
  required_version = "1.8.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.106.0"
    }

    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.50.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10"
    }
  }
}

provider "azurerm" {
  features {}
  #
  skip_provider_registration = true
  #
}

provider "azuread" {}