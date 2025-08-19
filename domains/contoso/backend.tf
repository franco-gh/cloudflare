# Terraform Cloud backend configuration for contoso domain family
terraform {
  cloud {
    organization = "your-terraform-cloud-org"
    workspaces {
      name = "contoso"
    }
  }
}
