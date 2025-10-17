# Cloudflare Terraform Infrastructure TODO

## 🔧 Immediate Setup Tasks

### Backend Configuration
- [ ] **Test current modules work** (priority: test first before optimizing)
- [ ] Update backend.tf files with actual Terraform Cloud organization name
- [ ] Implement environment variable approach for GitHub Actions:
  - [ ] Set `TF_CLOUD_ORGANIZATION` in GitHub secrets
  - [ ] Simplify backend.tf files to use environment variables
  - [ ] Update GitHub Actions workflow to set environment variables

### Testing & Validation
- [ ] Test modules/zone module functionality
- [ ] Test modules/dns module functionality
- [ ] Validate example domain configuration (iamfranco)
- [ ] Test domain creation script: `./scripts/new-domain.sh`
- [ ] Test DNS import script: `./scripts/import-dns.sh`

### Infrastructure Setup
- [ ] Replace placeholder credentials in shared/terraform.tfvars
- [ ] Create actual Terraform Cloud workspaces for domain families
- [ ] Test deployment with real domain
- [ ] Validate DNS record creation and management

### GitHub Actions Integration
- [ ] Create terraform.yml workflow for automated deployments
- [ ] Set up path-based change detection for domain families
- [ ] Configure PR-based terraform plan comments
- [ ] Test parallel deployment of multiple domain families

## 🎯 Current Focus
**PRIORITY**: Test that the Terraform modules actually work before optimizing backend configuration