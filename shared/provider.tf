terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# Cloudflare provider configuration
# Using variables from terraform.tfvars
provider "cloudflare" {
  api_token = var.cloudflare_api_token
  # account_id is passed to individual resources, not the provider
}