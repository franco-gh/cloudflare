terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare provider configuration
# Automatically reads CLOUDFLARE_API_TOKEN and CLOUDFLARE_ACCOUNT_ID environment variables
provider "cloudflare" {
  # api_token is read from CLOUDFLARE_API_TOKEN environment variable
  # account_id is read from CLOUDFLARE_ACCOUNT_ID environment variable
}