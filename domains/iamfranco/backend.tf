# Terraform Cloud backend configuration for iamfranco domain family
terraform {
  cloud {
    organization = "your-terraform-cloud-org"  # Update this with your actual organization
    workspaces {
      name = "iamfranco"
    }
  }
}