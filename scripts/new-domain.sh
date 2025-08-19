#!/bin/bash

# new-domain.sh - Create new domain configuration from templates
# Usage: ./scripts/new-domain.sh family-name domain-name [org-name]
# Example: ./scripts/new-domain.sh contoso contoso-com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
    echo "Usage: $0 <family-name> <domain-name> [terraform-cloud-org]"
    echo ""
    echo "Arguments:"
    echo "  family-name          Domain family name (e.g., contoso, iamfranco)"
    echo "  domain-name          Domain name (e.g., contoso-com, iamfranco-com)"
    echo "  terraform-cloud-org  Terraform Cloud organization (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 contoso contoso-com                    # Add domain to existing family"
    echo "  $0 newclient newclient-com my-org        # Create new family with org"
    echo "  $0 iamfranco iamfranco-net               # Add new TLD to existing family"
    exit 1
}

# Check arguments
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    print_error "Invalid number of arguments"
    show_usage
fi

FAMILY_NAME="$1"
DOMAIN_NAME="$2"
TERRAFORM_ORG="${3:-your-terraform-cloud-org}"

# Validate domain name format
if ! echo "$DOMAIN_NAME" | grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$'; then
    print_error "Domain name must contain only lowercase letters, numbers, and hyphens"
    exit 1
fi

# Convert domain name to actual domain (replace hyphens with dots, but keep the last part)
ACTUAL_DOMAIN=$(echo "$DOMAIN_NAME" | sed 's/-\([^-]*\)$/.\1/')

print_info "Creating domain configuration:"
print_info "  Family: $FAMILY_NAME"
print_info "  Domain Name: $DOMAIN_NAME"
print_info "  Actual Domain: $ACTUAL_DOMAIN"
print_info "  Terraform Org: $TERRAFORM_ORG"

# Create family directory if it doesn't exist
FAMILY_DIR="domains/$FAMILY_NAME"
DOMAIN_DIR="$FAMILY_DIR/$DOMAIN_NAME"

if [ ! -d "$FAMILY_DIR" ]; then
    print_info "Creating new domain family: $FAMILY_NAME"
    mkdir -p "$FAMILY_DIR"
    
    # Create family-level backend.tf
    cat > "$FAMILY_DIR/backend.tf" << EOF
# Terraform Cloud backend configuration for $FAMILY_NAME domain family
terraform {
  cloud {
    organization = "$TERRAFORM_ORG"
    workspaces {
      name = "$FAMILY_NAME"
    }
  }
}
EOF

    # Create family-level main.tf
    cat > "$FAMILY_DIR/main.tf" << EOF
# $FAMILY_NAME Domain Family Configuration
# This file manages all domains in the $FAMILY_NAME family

# Provider configuration
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# Cloudflare provider (reads from environment variables)
provider "cloudflare" {
  # api_token is read from CLOUDFLARE_API_TOKEN environment variable
  # account_id is read from CLOUDFLARE_ACCOUNT_ID environment variable
}

# Include individual domain configurations
module "${DOMAIN_NAME}" {
  source = "./${DOMAIN_NAME}"
}
EOF

    # Create family-level outputs.tf
    cat > "$FAMILY_DIR/outputs.tf" << EOF
# $FAMILY_NAME Domain Family Outputs

output "${DOMAIN_NAME}" {
  description = "$ACTUAL_DOMAIN domain details"
  value = {
    zone_id      = module.${DOMAIN_NAME}.zone_id
    nameservers  = module.${DOMAIN_NAME}.nameservers
    zone_status  = module.${DOMAIN_NAME}.zone_status
    dns_records  = module.${DOMAIN_NAME}.dns_records
  }
}
EOF

    print_info "Created new domain family structure"
else
    print_info "Adding domain to existing family: $FAMILY_NAME"
    
    # Add module to existing main.tf
    if ! grep -q "module \"$DOMAIN_NAME\"" "$FAMILY_DIR/main.tf"; then
        cat >> "$FAMILY_DIR/main.tf" << EOF

module "${DOMAIN_NAME}" {
  source = "./${DOMAIN_NAME}"
}
EOF
    fi
    
    # Add output to existing outputs.tf
    if ! grep -q "output \"$DOMAIN_NAME\"" "$FAMILY_DIR/outputs.tf"; then
        cat >> "$FAMILY_DIR/outputs.tf" << EOF

output "${DOMAIN_NAME}" {
  description = "$ACTUAL_DOMAIN domain details"
  value = {
    zone_id      = module.${DOMAIN_NAME}.zone_id
    nameservers  = module.${DOMAIN_NAME}.nameservers
    zone_status  = module.${DOMAIN_NAME}.zone_status
    dns_records  = module.${DOMAIN_NAME}.dns_records
  }
}
EOF
    fi
fi

# Check if domain directory already exists
if [ -d "$DOMAIN_DIR" ]; then
    print_warn "Domain directory already exists: $DOMAIN_DIR"
    read -p "Do you want to overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted"
        exit 0
    fi
fi

# Create domain directory
mkdir -p "$DOMAIN_DIR"

# Create domain main.tf
cat > "$DOMAIN_DIR/main.tf" << EOF
# $ACTUAL_DOMAIN Domain Configuration

# Create the zone
module "zone" {
  source = "../../../modules/zone"

  domain_name = var.domain_name
  zone_plan   = var.zone_plan

  # SSL/TLS settings
  ssl_mode                 = var.ssl_mode
  always_use_https        = var.always_use_https
  min_tls_version         = var.min_tls_version
  automatic_https_rewrites = var.automatic_https_rewrites

  # Security settings
  security_level = var.security_level
  challenge_ttl  = var.challenge_ttl
  browser_check  = var.browser_check

  # Performance settings
  brotli      = var.brotli
  minify_css  = var.minify_css
  minify_html = var.minify_html
  minify_js   = var.minify_js

  # Development mode
  development_mode = var.development_mode

  # DNSSEC
  enable_dnssec = var.enable_dnssec

  tags = var.tags
}

# Create DNS records
module "dns" {
  source = "../../../modules/dns"

  zone_id     = module.zone.zone_id
  dns_records = var.dns_records

  depends_on = [module.zone]
}
EOF

# Create domain variables.tf
cat > "$DOMAIN_DIR/variables.tf" << EOF
# $ACTUAL_DOMAIN Domain Variables

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "$ACTUAL_DOMAIN"
}

variable "zone_plan" {
  description = "Cloudflare zone plan"
  type        = string
  default     = "free"
}

# SSL/TLS Configuration
variable "ssl_mode" {
  description = "SSL/TLS encryption mode"
  type        = string
  default     = "full"
}

variable "always_use_https" {
  description = "Always use HTTPS"
  type        = bool
  default     = true
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "1.2"
}

variable "automatic_https_rewrites" {
  description = "Automatic HTTPS rewrites"
  type        = bool
  default     = true
}

# Security Configuration
variable "security_level" {
  description = "Security level for the zone"
  type        = string
  default     = "medium"
}

variable "challenge_ttl" {
  description = "Challenge TTL in seconds"
  type        = number
  default     = 1800
}

variable "browser_check" {
  description = "Browser integrity check"
  type        = string
  default     = "on"
}

# Performance Configuration
variable "brotli" {
  description = "Enable Brotli compression"
  type        = string
  default     = "on"
}

variable "minify_css" {
  description = "Minify CSS files"
  type        = bool
  default     = true
}

variable "minify_html" {
  description = "Minify HTML files"
  type        = bool
  default     = true
}

variable "minify_js" {
  description = "Minify JavaScript files"
  type        = bool
  default     = true
}

variable "development_mode" {
  description = "Enable development mode (bypass cache)"
  type        = bool
  default     = false
}

# DNSSEC Configuration
variable "enable_dnssec" {
  description = "Enable DNSSEC for the zone"
  type        = bool
  default     = true
}

# DNS Records Configuration
variable "dns_records" {
  description = "DNS records to create for $ACTUAL_DOMAIN"
  type = map(object({
    type     = string
    name     = string
    content  = string
    ttl      = optional(number, 1)
    proxied  = optional(bool, false)
    priority = optional(number)
    comment  = optional(string)
  }))
  default = {}
}

# Tags
variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    domain     = "$ACTUAL_DOMAIN"
    family     = "$FAMILY_NAME"
    managed_by = "terraform"
  }
}
EOF

# Create domain outputs.tf
cat > "$DOMAIN_DIR/outputs.tf" << EOF
# $ACTUAL_DOMAIN Domain Outputs

output "zone_id" {
  description = "Zone ID for $ACTUAL_DOMAIN"
  value       = module.zone.zone_id
}

output "nameservers" {
  description = "Cloudflare nameservers for $ACTUAL_DOMAIN"
  value       = module.zone.name_servers
}

output "zone_status" {
  description = "Zone status"
  value       = module.zone.status
}

output "verification_key" {
  description = "Zone verification key"
  value       = module.zone.verification_key
  sensitive   = true
}

output "dns_records" {
  description = "Created DNS records"
  value       = module.dns.record_details
}

output "record_fqdns" {
  description = "Fully qualified domain names"
  value       = module.dns.record_fqdns
}

output "a_records" {
  description = "A record details"
  value       = module.dns.a_records
}

output "cname_records" {
  description = "CNAME record details"
  value       = module.dns.cname_records
}

output "mx_records" {
  description = "MX record details"
  value       = module.dns.mx_records
}

output "txt_records" {
  description = "TXT record details"
  value       = module.dns.txt_records
}
EOF

# Create domain terraform.tfvars with sample records
cat > "$DOMAIN_DIR/terraform.tfvars" << EOF
# $ACTUAL_DOMAIN DNS Configuration
# Update these values according to your DNS requirements

domain_name = "$ACTUAL_DOMAIN"
zone_plan   = "free"

# DNS Records Configuration
dns_records = {
  # Root domain (A record)
  "root" = {
    type    = "A"
    name    = "@"
    content = "192.168.1.100"  # Replace with your server IP
    ttl     = 1               # Auto TTL
    proxied = false
    comment = "Root domain A record"
  }

  # WWW subdomain (CNAME to root)
  "www" = {
    type    = "CNAME"
    name    = "www"
    content = "$ACTUAL_DOMAIN"
    ttl     = 1
    proxied = false
    comment = "WWW subdomain"
  }

  # Mail server (MX record)
  "mail_mx" = {
    type     = "MX"
    name     = "@"
    content  = "mail.$ACTUAL_DOMAIN"
    ttl      = 1
    priority = 10
    proxied  = false
    comment  = "Primary mail server"
  }

  # Mail server A record
  "mail_a" = {
    type    = "A"
    name    = "mail"
    content = "192.168.1.101"  # Replace with your mail server IP
    ttl     = 1
    proxied = false
    comment = "Mail server A record"
  }

  # SPF record for email
  "spf" = {
    type    = "TXT"
    name    = "@"
    content = "v=spf1 mx a:mail.$ACTUAL_DOMAIN -all"
    ttl     = 1
    proxied = false
    comment = "SPF record for email authentication"
  }
}

# Zone settings
ssl_mode                 = "full"
always_use_https        = true
min_tls_version         = "1.2"
automatic_https_rewrites = true

security_level = "medium"
challenge_ttl  = 1800
browser_check  = "on"

brotli      = "on"
minify_css  = true
minify_html = true
minify_js   = true

development_mode = false
enable_dnssec    = true
EOF

print_info "✅ Successfully created domain configuration!"
print_info ""
print_info "Next steps:"
print_info "1. Edit $DOMAIN_DIR/terraform.tfvars with your actual DNS records"
print_info "2. Update backend.tf with your Terraform Cloud organization if needed"
print_info "3. Test the configuration:"
print_info "   cd $FAMILY_DIR"
print_info "   terraform init"
print_info "   terraform plan"
print_info "4. Apply when ready:"
print_info "   terraform apply"
print_info ""
print_info "Configuration created at: $DOMAIN_DIR"