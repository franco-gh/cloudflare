# Template backend configuration for Terraform Cloud
# This file serves as a reference for domain families to configure their backends

# Example backend configuration:
# terraform {
#   cloud {
#     organization = "your-terraform-cloud-org"
#     workspaces {
#       name = "domain-family-name"
#     }
#   }
# }

# Each domain family should copy this structure and customize:
# - organization: Your Terraform Cloud organization name
# - workspaces.name: The family name (e.g., "iamfranco", "contoso")

# To use this template:
# 1. Copy to your domain family directory as backend.tf
# 2. Update organization name
# 3. Update workspace name to match your family name
# 4. Run terraform init to initialize the backend