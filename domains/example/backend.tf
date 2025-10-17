# Terraform Cloud backend configuration for example domain family
terraform {
  cloud {
    organization = "CUM"
    workspaces {
      name = "example"
    }
  }
}
