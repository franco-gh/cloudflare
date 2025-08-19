#!/bin/bash

# import-dns.sh - Import existing DNS records from Cloudflare into Terraform
# Usage: ./scripts/import-dns.sh domain.com [family-name]
# Example: ./scripts/import-dns.sh example.com myclient

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Function to show usage
show_usage() {
    echo "Usage: $0 <domain> [family-name]"
    echo ""
    echo "Arguments:"
    echo "  domain       The domain to import (e.g., example.com)"
    echo "  family-name  Domain family name (optional, defaults to domain without TLD)"
    echo ""
    echo "Examples:"
    echo "  $0 example.com                    # Import example.com to 'example' family"
    echo "  $0 contoso.net contoso            # Import contoso.net to 'contoso' family"
    echo ""
    echo "Prerequisites:"
    echo "  - CLOUDFLARE_API_TOKEN environment variable"
    echo "  - CLOUDFLARE_ACCOUNT_ID environment variable"
    echo "  - jq command-line JSON processor"
    echo "  - curl command-line tool"
    exit 1
}

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    print_error "Invalid number of arguments"
    show_usage
fi

DOMAIN="$1"
FAMILY_NAME="${2:-$(echo "$DOMAIN" | sed 's/\.[^.]*$//')}"  # Default to domain without TLD

# Validate domain format
if ! echo "$DOMAIN" | grep -qE '^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]\.[a-zA-Z]{2,}$'; then
    print_error "Invalid domain format: $DOMAIN"
    exit 1
fi

# Convert domain to terraform naming convention
DOMAIN_NAME=$(echo "$DOMAIN" | sed 's/\./-/g')

print_info "Importing DNS records for domain: $DOMAIN"
print_info "Target family: $FAMILY_NAME"
print_info "Target domain config: $DOMAIN_NAME"

# Check prerequisites
if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
    print_error "CLOUDFLARE_API_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$CLOUDFLARE_ACCOUNT_ID" ]; then
    print_error "CLOUDFLARE_ACCOUNT_ID environment variable is required"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is required but not installed. Please install jq."
    exit 1
fi

if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install curl."
    exit 1
fi

# Create temporary files
TEMP_DIR=$(mktemp -d)
ZONE_INFO_FILE="$TEMP_DIR/zone_info.json"
RECORDS_FILE="$TEMP_DIR/records.json"
TERRAFORM_CONFIG="$TEMP_DIR/terraform_config.tf"
IMPORT_COMMANDS="$TEMP_DIR/import_commands.sh"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

print_step "1/5 Fetching zone information from Cloudflare..."

# Get zone information
ZONE_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/v4/zones?name=$DOMAIN" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")

if ! echo "$ZONE_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
    print_error "Failed to fetch zone information"
    echo "$ZONE_RESPONSE" | jq '.errors' 2>/dev/null || echo "$ZONE_RESPONSE"
    exit 1
fi

ZONE_COUNT=$(echo "$ZONE_RESPONSE" | jq '.result | length')
if [ "$ZONE_COUNT" -eq 0 ]; then
    print_error "Domain $DOMAIN not found in Cloudflare account"
    exit 1
fi

if [ "$ZONE_COUNT" -gt 1 ]; then
    print_warn "Multiple zones found for $DOMAIN, using the first one"
fi

# Extract zone information
ZONE_ID=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].id')
ZONE_NAME=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].name')
ZONE_STATUS=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].status')
ZONE_PLAN=$(echo "$ZONE_RESPONSE" | jq -r '.result[0].plan.name' | tr '[:upper:]' '[:lower:]')

echo "$ZONE_RESPONSE" | jq '.result[0]' > "$ZONE_INFO_FILE"

print_info "Found zone: $ZONE_NAME (ID: $ZONE_ID, Status: $ZONE_STATUS, Plan: $ZONE_PLAN)"

print_step "2/5 Fetching DNS records..."

# Get DNS records
RECORDS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/v4/zones/$ZONE_ID/dns_records" \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H "Content-Type: application/json")

if ! echo "$RECORDS_RESPONSE" | jq -e '.success' >/dev/null 2>&1; then
    print_error "Failed to fetch DNS records"
    echo "$RECORDS_RESPONSE" | jq '.errors' 2>/dev/null || echo "$RECORDS_RESPONSE"
    exit 1
fi

echo "$RECORDS_RESPONSE" | jq '.result' > "$RECORDS_FILE"

RECORD_COUNT=$(jq 'length' "$RECORDS_FILE")
print_info "Found $RECORD_COUNT DNS records"

print_step "3/5 Generating Terraform configuration..."

# Generate Terraform configuration
cat > "$TERRAFORM_CONFIG" << EOF
# Generated Terraform configuration for $DOMAIN
# Created by import-dns.sh on $(date)

# DNS Records Configuration
dns_records = {
EOF

# Process each record
jq -r '.[] | @base64' "$RECORDS_FILE" | while read -r record; do
    # Decode the record
    DECODED=$(echo "$record" | base64 -d)
    
    RECORD_ID=$(echo "$DECODED" | jq -r '.id')
    RECORD_TYPE=$(echo "$DECODED" | jq -r '.type')
    RECORD_NAME=$(echo "$DECODED" | jq -r '.name')
    RECORD_CONTENT=$(echo "$DECODED" | jq -r '.content')
    RECORD_TTL=$(echo "$DECODED" | jq -r '.ttl')
    RECORD_PROXIED=$(echo "$DECODED" | jq -r '.proxied')
    RECORD_PRIORITY=$(echo "$DECODED" | jq -r '.priority // empty')
    RECORD_COMMENT=$(echo "$DECODED" | jq -r '.comment // empty')
    
    # Skip certain record types that are auto-managed
    case "$RECORD_TYPE" in
        "NS"|"SOA")
            continue
            ;;
    esac
    
    # Generate record name for terraform
    if [ "$RECORD_NAME" = "$DOMAIN" ]; then
        TF_RECORD_NAME="root"
    else
        TF_RECORD_NAME=$(echo "$RECORD_NAME" | sed "s/\.$DOMAIN$//" | sed 's/\./_/g' | sed 's/-/_/g')
        if [ -z "$TF_RECORD_NAME" ]; then
            TF_RECORD_NAME="root"
        fi
    fi
    
    # Make sure record name is unique by appending type if needed
    TF_RECORD_NAME="${TF_RECORD_NAME}_${RECORD_TYPE,,}"
    
    # Generate Terraform record
    cat >> "$TERRAFORM_CONFIG" << EOF
  "$TF_RECORD_NAME" = {
    type    = "$RECORD_TYPE"
    name    = "$([ "$RECORD_NAME" = "$DOMAIN" ] && echo "@" || echo "${RECORD_NAME%.$DOMAIN}")"
    content = "$RECORD_CONTENT"
    ttl     = $RECORD_TTL
    proxied = $RECORD_PROXIED
$([ -n "$RECORD_PRIORITY" ] && [ "$RECORD_PRIORITY" != "null" ] && echo "    priority = $RECORD_PRIORITY")
$([ -n "$RECORD_COMMENT" ] && [ "$RECORD_COMMENT" != "null" ] && echo "    comment  = \"$RECORD_COMMENT\"")
  }
EOF
done

cat >> "$TERRAFORM_CONFIG" << EOF
}

# Zone settings
domain_name = "$DOMAIN"
zone_plan   = "$ZONE_PLAN"

# SSL/TLS settings (adjust as needed)
ssl_mode                 = "full"
always_use_https        = true
min_tls_version         = "1.2"
automatic_https_rewrites = true

# Security settings (adjust as needed)
security_level = "medium"
challenge_ttl  = 1800
browser_check  = "on"

# Performance settings (adjust as needed)
brotli      = "on"
minify_css  = true
minify_html = true
minify_js   = true

development_mode = false
enable_dnssec    = true
EOF

print_step "4/5 Generating import commands..."

# Generate import commands
cat > "$IMPORT_COMMANDS" << 'EOF'
#!/bin/bash
# Terraform import commands for existing DNS records
# Run these commands from your domain family directory

set -e

echo "Importing zone..."
EOF

echo "terraform import module.${DOMAIN_NAME}.module.zone.cloudflare_zone.main $ZONE_ID" >> "$IMPORT_COMMANDS"

echo "" >> "$IMPORT_COMMANDS"
echo "echo \"Importing DNS records...\"" >> "$IMPORT_COMMANDS"

# Generate import commands for DNS records
jq -r '.[] | @base64' "$RECORDS_FILE" | while read -r record; do
    DECODED=$(echo "$record" | base64 -d)
    
    RECORD_ID=$(echo "$DECODED" | jq -r '.id')
    RECORD_TYPE=$(echo "$DECODED" | jq -r '.type')
    RECORD_NAME=$(echo "$DECODED" | jq -r '.name')
    
    # Skip auto-managed records
    case "$RECORD_TYPE" in
        "NS"|"SOA")
            continue
            ;;
    esac
    
    # Generate record name for terraform
    if [ "$RECORD_NAME" = "$DOMAIN" ]; then
        TF_RECORD_NAME="root"
    else
        TF_RECORD_NAME=$(echo "$RECORD_NAME" | sed "s/\.$DOMAIN$//" | sed 's/\./_/g' | sed 's/-/_/g')
        if [ -z "$TF_RECORD_NAME" ]; then
            TF_RECORD_NAME="root"
        fi
    fi
    
    TF_RECORD_NAME="${TF_RECORD_NAME}_${RECORD_TYPE,,}"
    
    echo "terraform import 'module.${DOMAIN_NAME}.module.dns.cloudflare_dns_record.records[\"$TF_RECORD_NAME\"]' $RECORD_ID" >> "$IMPORT_COMMANDS"
done

cat >> "$IMPORT_COMMANDS" << 'EOF'

echo ""
echo "Import completed! Next steps:"
echo "1. Review the generated terraform.tfvars configuration"
echo "2. Run 'terraform plan' to verify the import"
echo "3. Make any necessary adjustments to the configuration"
EOF

chmod +x "$IMPORT_COMMANDS"

print_step "5/5 Creating output files..."

# Create output directory
OUTPUT_DIR="imported_configs"
mkdir -p "$OUTPUT_DIR"

# Copy files to output directory
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DOMAIN_OUTPUT_DIR="$OUTPUT_DIR/${DOMAIN}_${TIMESTAMP}"
mkdir -p "$DOMAIN_OUTPUT_DIR"

cp "$TERRAFORM_CONFIG" "$DOMAIN_OUTPUT_DIR/terraform.tfvars"
cp "$IMPORT_COMMANDS" "$DOMAIN_OUTPUT_DIR/import.sh"
cp "$ZONE_INFO_FILE" "$DOMAIN_OUTPUT_DIR/zone_info.json"
cp "$RECORDS_FILE" "$DOMAIN_OUTPUT_DIR/dns_records.json"

# Create README
cat > "$DOMAIN_OUTPUT_DIR/README.md" << EOF
# DNS Import for $DOMAIN

Generated on: $(date)
Zone ID: $ZONE_ID
Records imported: $RECORD_COUNT

## Files:

- \`terraform.tfvars\` - Terraform configuration with DNS records
- \`import.sh\` - Shell script with terraform import commands  
- \`zone_info.json\` - Original zone information from Cloudflare
- \`dns_records.json\` - Original DNS records from Cloudflare

## Next Steps:

1. Create domain configuration using new-domain.sh:
   \`\`\`bash
   ./scripts/new-domain.sh $FAMILY_NAME $DOMAIN_NAME
   \`\`\`

2. Replace the generated terraform.tfvars with this imported version:
   \`\`\`bash
   cp $DOMAIN_OUTPUT_DIR/terraform.tfvars domains/$FAMILY_NAME/$DOMAIN_NAME/terraform.tfvars
   \`\`\`

3. Initialize and import:
   \`\`\`bash
   cd domains/$FAMILY_NAME
   terraform init
   bash ../../$DOMAIN_OUTPUT_DIR/import.sh
   \`\`\`

4. Verify the import:
   \`\`\`bash
   terraform plan
   \`\`\`

The plan should show no changes if the import was successful.
EOF

print_info "✅ DNS import completed successfully!"
print_info ""
print_info "📁 Output files created in: $DOMAIN_OUTPUT_DIR"
print_info ""
print_info "📋 Summary:"
print_info "  Domain: $DOMAIN"
print_info "  Zone ID: $ZONE_ID" 
print_info "  Records: $RECORD_COUNT"
print_info "  Plan: $ZONE_PLAN"
print_info ""
print_info "🚀 Next steps:"
print_info "1. Review the generated configuration: $DOMAIN_OUTPUT_DIR/terraform.tfvars"
print_info "2. Create domain structure: ./scripts/new-domain.sh $FAMILY_NAME $DOMAIN_NAME"
print_info "3. Replace terraform.tfvars with the imported version"
print_info "4. Run the import script: $DOMAIN_OUTPUT_DIR/import.sh"
print_info "5. Verify with: terraform plan"
print_info ""
print_info "📖 See $DOMAIN_OUTPUT_DIR/README.md for detailed instructions"