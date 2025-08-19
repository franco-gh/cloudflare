# Cloudflare Multi-Domain DNS Management with Terraform

This repository manages DNS records for 100+ domains across multiple domain families using Terraform. It implements a scalable "DNS as Code" solution with modular architecture, family-based organization, and automated workflows.

## Architecture Overview

### Scalable Multi-Domain Design
- **Domain Families**: Related TLDs grouped together (contoso.com, contoso.net, contoso.co)
- **Modular Structure**: Reusable zone and DNS modules for consistency
- **Family Workspaces**: Terraform Cloud workspace per domain family
- **Independent State**: Each family has isolated state management

### Authentication Strategy
- **Environment Variables**: `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`
- **Secure**: No credentials committed to git
- **CI/CD Ready**: GitHub Actions secrets integration

## Repository Structure

```
terraform/
├── modules/                    # Reusable infrastructure modules
│   ├── zone/                  # Zone creation (cloudflare_zone)
│   └── dns/                   # DNS records (cloudflare_dns_record)
├── domains/                   # Domain family configurations
│   ├── iamfranco/             # Domain family (workspace: iamfranco)
│   │   ├── backend.tf         # Terraform Cloud workspace config
│   │   └── iamfranco-com/     # Individual domain config
│   └── contoso/               # Multi-TLD family (workspace: contoso)
│       ├── contoso-com/
│       ├── contoso-net/
│       └── contoso-co/
├── shared/                    # Common configurations
│   ├── provider.tf            # Cloudflare provider (env vars)
│   └── variables.tf           # Shared variable definitions
├── scripts/                   # Automation tools
│   ├── new-domain.sh          # Create new domain from template
│   ├── import-dns.sh          # Import existing DNS records
│   └── setup.sh               # Environment validation
└── .github/workflows/         # Family-based CI/CD
```

## Implementation Workflow

### Adding New Domain Family
1. **Run Setup**: `./scripts/setup.sh` (validates environment)
2. **Create Family**: `./scripts/new-domain.sh family-name domain-name`
3. **Configure DNS**: Edit `domains/family-name/domain-name/terraform.tfvars`
4. **Test Locally**: `cd domains/family-name && terraform plan`
5. **Deploy**: Create PR → Review plan → Merge → Auto-deploy

### Adding Domain to Existing Family
1. **Add Domain**: `./scripts/new-domain.sh existing-family new-domain`
2. **Configure**: Edit DNS records in terraform.tfvars
3. **Deploy**: Standard PR workflow

### Importing Existing Domain
1. **Import Records**: `./scripts/import-dns.sh existing-domain.com`
2. **Review Generated Config**: Check imported configuration
3. **Apply Import**: Run generated terraform import commands
4. **Commit**: Add to git and deploy via PR

## Environment Setup

### Prerequisites
```bash
# Install required tools
terraform --version  # >= 1.0
gh --version         # GitHub CLI

# Set Cloudflare credentials
export CLOUDFLARE_API_TOKEN="your_api_token"
export CLOUDFLARE_ACCOUNT_ID="your_account_id"

# Validate setup
./scripts/setup.sh
```

### Terraform Cloud Workspaces
- Each domain family has its own workspace
- Workspace naming: `family-name` (e.g., `iamfranco`, `contoso`)
- Variables set at workspace level for family-specific settings

## Development Workflow

### Standard Changes
1. **Create Branch**: `git checkout -b feature/update-contoso-dns`
2. **Make Changes**: Edit domain-specific `terraform.tfvars`
3. **Test Locally**: `cd domains/family-name && terraform plan`
4. **Create PR**: `gh pr create --title "Update DNS records"`
5. **Review Plan**: CI/CD posts terraform plan in PR comments
6. **Merge**: Auto-deploys only changed family

### CI/CD Optimization
- **Path Detection**: Only deploys changed domain families
- **Parallel Deployment**: Multiple families can deploy simultaneously
- **DNS Stability**: Unchanged records remain unaffected

## DNS Record Management

### Example DNS Configuration
```hcl
# domains/iamfranco/iamfranco-com/terraform.tfvars
dns_records = {
  "root" = {
    type    = "A"
    name    = "@"
    content = "192.168.1.100"
    ttl     = 1
    proxied = false
  }
  "www" = {
    type    = "CNAME"
    name    = "www"
    content = "iamfranco.com"
    ttl     = 1
    proxied = false
  }
  "mail" = {
    type     = "MX"
    name     = "@"
    content  = "mail.iamfranco.com"
    priority = 10
    ttl      = 1
  }
}
```

### DNS Safety Features
- **Atomic Updates**: Cloudflare API ensures atomic record changes
- **Unchanged Records Protected**: Terraform only modifies changed records
- **Fast Propagation**: Cloudflare DNS updates propagate in 1-2 minutes
- **State Locking**: Terraform Cloud prevents concurrent modifications

## Script Usage

### Create New Domain
```bash
# Create new family with first domain
./scripts/new-domain.sh mynewclient mynewclient-com

# Add domain to existing family
./scripts/new-domain.sh contoso contoso-org
```

### Import Existing Domain
```bash
# Import from Cloudflare to Terraform
./scripts/import-dns.sh existing-domain.com

# Follow generated instructions to complete import
```

### Environment Validation
```bash
# Check setup and credentials
./scripts/setup.sh
```

## Local Development

### Working with Specific Domain Family
```bash
# Navigate to family directory
cd domains/iamfranco

# Initialize (first time only)
terraform init

# Plan changes
terraform plan

# Apply changes (use PR workflow instead)
terraform apply
```

### Testing Changes Safely
1. **Always plan first**: `terraform plan` before any apply
2. **Use staging workspace**: Test major changes in separate workspace
3. **Small incremental changes**: Avoid bulk DNS modifications
4. **Monitor propagation**: Watch DNS resolution after changes

## Best Practices

### DNS Management
- Set appropriate TTL values (300s for frequently changed records)
- Use CNAME records for flexibility where possible
- Group related records in logical families
- Test changes in non-production domains first

### State Management
- Never force-unlock state without team coordination
- Use Terraform Cloud for consistent state management
- Keep family state separate for isolation
- Regular state backups via Terraform Cloud

### Security
- Rotate Cloudflare API tokens regularly
- Use GitHub secrets for CI/CD credentials
- Limit API token permissions to necessary scopes
- Monitor API token usage in Cloudflare dashboard

## Troubleshooting

### Common Issues
- **Authentication**: Check environment variables with `./scripts/setup.sh`
- **State Lock**: Clear via Terraform Cloud UI if needed
- **DNS Propagation**: Allow 1-2 minutes for Cloudflare propagation
- **Import Conflicts**: Use `terraform import` to resolve state mismatches

### Emergency Procedures
1. **Revert DNS Changes**: Use git to revert to previous working state
2. **Manual Override**: Use Cloudflare dashboard for emergency changes
3. **State Recovery**: Restore from Terraform Cloud backup if needed

## Support

### Resources
- Cloudflare API Documentation
- Terraform Cloudflare Provider Documentation
- Terraform Cloud Documentation

### Team Workflow
- Use descriptive commit messages for DNS changes
- Include affected domains in PR titles
- Tag team members for review of critical DNS changes
- Document non-standard configurations in PR comments