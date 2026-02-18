terraform {
  required_version = ">=0.12"

  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.47"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.00"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}


provider "volterra" {
  api_p12_file     = "kulland-api-creds.p12"
  url              = "https://${var.tenant}.console.ves.volterra.io/api"
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
}