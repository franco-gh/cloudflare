# example Domain Family Configuration
# This file manages all domains in the example family (placeholder/demo domains)

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

# Include individual domain configurations
module "example-com" {
  source = "./example-com"
}

module "example-net" {
  source = "./example-net"
}

module "example-co" {
  source = "./example-co"
}
