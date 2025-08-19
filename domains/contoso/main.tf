# contoso Domain Family Configuration
# This file manages all domains in the contoso family

# Provider configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare provider (reads from environment variables)
provider "cloudflare" {
  # api_token is read from CLOUDFLARE_API_TOKEN environment variable
  # account_id is read from CLOUDFLARE_ACCOUNT_ID environment variable
}

# Include individual domain configurations
module "contoso-com" {
  source = "./contoso-com"
}

module "contoso-net" {
  source = "./contoso-net"
}

module "contoso-co" {
  source = "./contoso-co"
}
