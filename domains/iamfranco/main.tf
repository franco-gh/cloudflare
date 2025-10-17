# iamfranco Domain Family Configuration
# This file manages all domains in the iamfranco family

# Provider configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# Cloudflare provider (reads from environment variables)
provider "cloudflare" {
  # api_token is read from CLOUDFLARE_API_TOKEN environment variable
  # account_id is read from CLOUDFLARE_ACCOUNT_ID environment variable
}

# Variables
variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

# Include individual domain configurations
module "iamfranco_com" {
  source = "./iamfranco-com"

  # Pass account ID from environment variable
  account_id = var.account_id
}