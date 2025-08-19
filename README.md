# Cloudflare DNS Management with Terraform

Scalable multi-domain DNS management infrastructure using Terraform, organized by domain families for efficient management of 100+ domains.

## 🏗️ Architecture

```
📁 Project Structure
├── domains/                    # Domain families
│   ├── iamfranco/             # Family: iamfranco
│   │   ├── backend.tf         # Terraform Cloud workspace
│   │   ├── main.tf            # Family orchestration
│   │   └── iamfranco-com/     # Domain: iamfranco.com
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars
│   └── contoso/               # Family: contoso (multi-TLD example)
│       ├── backend.tf
│       ├── main.tf
│       ├── contoso-com/       # contoso.com
│       ├── contoso-net/       # contoso.net  
│       └── contoso-co/        # contoso.co
├── modules/                   # Reusable Terraform modules
│   ├── zone/                  # Zone management module
│   └── dns/                   # DNS records module
├── shared/                    # Shared configurations
│   └── provider.tf            # Cloudflare provider setup
└── scripts/                   # Automation scripts
    ├── setup.sh               # Environment validation
    ├── new-domain.sh          # Create new domain configs
    └── import-dns.sh          # Import existing DNS records
```

## 🚀 Quick Start

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [jq](https://stedolan.github.io/jq/) (for import script)
- [curl](https://curl.se/) (for API calls)
- Cloudflare account with API access
- [Terraform Cloud](https://cloud.hashicorp.com/products/terraform) account (recommended)

### 2. Environment Setup

```bash
# Clone the repository
git clone https://github.com/franco-gh/cloudflare.git
cd cloudflare

# Set up environment variables
export CLOUDFLARE_API_TOKEN="your_api_token_here"
export CLOUDFLARE_ACCOUNT_ID="your_account_id_here"

# Validate your environment
./scripts/setup.sh
```

### 3. Configure Terraform Cloud

Update the backend configuration in domain family directories:

```bash
# Edit domains/*/backend.tf
terraform {
  cloud {
    organization = "your-terraform-cloud-org"
    workspaces {
      name = "family-name"  # e.g., "iamfranco", "contoso"
    }
  }
}
```

### 4. Deploy Your First Domain

```bash
# Navigate to a domain family
cd domains/iamfranco

# Review and update the configuration
vim iamfranco-com/terraform.tfvars

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

## 📋 Domain Management

### Creating New Domains

Use the automation script to create new domain configurations:

```bash
# Create a domain in an existing family
./scripts/new-domain.sh iamfranco iamfranco-net

# Create a new domain family
./scripts/new-domain.sh newclient newclient-com
```

### Importing Existing Domains

Import DNS records from existing Cloudflare zones:

```bash
# Import domain records
./scripts/import-dns.sh example.com myclient

# Follow the generated instructions to complete the import
```

### Family Organization

Domain families group related TLDs together:

- **iamfranco family**: iamfranco.com, iamfranco.net, iamfranco.org
- **contoso family**: contoso.com, contoso.net, contoso.co
- **client1 family**: client1.com, client1.app

Each family has its own Terraform Cloud workspace for isolated state management.

## 🛠️ Available Scripts

### `./scripts/setup.sh`
Environment validation and setup assistance
```bash
./scripts/setup.sh           # Validate environment
./scripts/setup.sh --fix     # Attempt automatic fixes
```

### `./scripts/new-domain.sh`
Create new domain configurations
```bash
./scripts/new-domain.sh <family-name> <domain-name>
./scripts/new-domain.sh contoso contoso-org
```

### `./scripts/import-dns.sh`
Import existing DNS records from Cloudflare
```bash
./scripts/import-dns.sh <domain> [family-name]
./scripts/import-dns.sh example.com myclient
```

## ⚙️ Configuration

### DNS Records

Configure DNS records in `terraform.tfvars`:

```hcl
dns_records = {
  "root" = {
    type    = "A"
    name    = "@"
    content = "192.168.1.100"
    ttl     = 1
    proxied = false
    comment = "Root domain A record"
  }
  
  "www" = {
    type    = "CNAME"
    name    = "www"
    content = "example.com"
    ttl     = 1
    proxied = true
    comment = "WWW subdomain"
  }
  
  "mail_mx" = {
    type     = "MX"
    name     = "@"
    content  = "mail.example.com"
    priority = 10
    ttl      = 1
    proxied  = false
    comment  = "Primary mail server"
  }
}
```

### Zone Settings

```hcl
# SSL/TLS Configuration
ssl_mode                 = "full"
always_use_https        = true
min_tls_version         = "1.2"
automatic_https_rewrites = true

# Security Settings
security_level = "medium"
challenge_ttl  = 1800
browser_check  = "on"

# Performance Settings
brotli      = "on"
minify_css  = true
minify_html = true
minify_js   = true

# DNSSEC
enable_dnssec = true
```

## 🔄 CI/CD Workflow

The repository includes GitHub Actions workflow for automated deployments:

- **Path-based detection**: Only deploys changed domain families
- **Parallel execution**: Multiple families deploy simultaneously
- **Pull request plans**: Shows planned changes for review
- **Production protection**: Requires approval for main branch deployments

### Workflow Features:
- ✅ Detects changes in domain families automatically
- ✅ Runs terraform plan on pull requests
- ✅ Comments plan results on PRs
- ✅ Deploys to production on main branch merge
- ✅ Supports multiple families in parallel

## 📚 Module Documentation

### Zone Module (`modules/zone/`)

Manages Cloudflare zone configuration including:
- Zone creation and settings
- SSL/TLS configuration
- Security settings (firewall, DDoS protection)
- Performance optimization (caching, compression)
- DNSSEC management

### DNS Module (`modules/dns/`)

Manages DNS records with support for:
- All DNS record types (A, AAAA, CNAME, MX, TXT, SRV, etc.)
- Cloudflare proxy settings
- TTL configuration
- Priority settings for MX/SRV records
- Comments and documentation

## 🔐 Security Best Practices

- **Environment Variables**: Credentials stored as environment variables, never in code
- **API Token Scope**: Use scoped API tokens with minimal required permissions
- **State Isolation**: Each domain family has separate Terraform state
- **Change Review**: All changes reviewed via pull request process
- **Terraform Cloud**: Secure remote state management

## 🚨 Troubleshooting

### Common Issues

**Q: Terraform init fails with authentication error**
```bash
# Verify your API token and account ID
./scripts/setup.sh
```

**Q: DNS changes not applying**
```bash
# Check for typos in record configuration
terraform validate
terraform plan
```

**Q: Import script fails**
```bash
# Ensure domain exists in your Cloudflare account
curl -X GET "https://api.cloudflare.com/v4/zones?name=example.com" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

### Getting Help

1. Run the setup script: `./scripts/setup.sh`
2. Check the [claude.md](claude.md) for detailed implementation guide
3. Review Terraform logs for specific error messages
4. Verify API permissions and rate limits

## 📖 Additional Resources

- [claude.md](claude.md) - Complete implementation guide and workflows
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Cloud Documentation](https://www.terraform.io/cloud-docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with a domain family
5. Submit a pull request

---

**Built with Terraform and Cloudflare for scalable DNS management** 🌐