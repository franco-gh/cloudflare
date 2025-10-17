# Terraform Cloud backend configuration for iamfranco domain family
terraform {
  cloud {
    organization = "CUM"
    workspaces {
      name = "iamfranco"
    }
  }
}