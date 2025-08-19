#!/bin/bash

# setup.sh - Environment setup and validation for Cloudflare DNS management
# Usage: ./scripts/setup.sh [--fix]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[CHECK]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_failure() { echo -e "${RED}[✗]${NC} $1"; }
print_header() { echo -e "${BOLD}${BLUE}$1${NC}"; }

# Flags
FIX_MODE=false
if [ "$1" = "--fix" ]; then
    FIX_MODE=true
fi

# Error tracking
ERRORS=0
WARNINGS=0

# Function to increment error counter
add_error() {
    ERRORS=$((ERRORS + 1))
}

# Function to increment warning counter
add_warning() {
    WARNINGS=$((WARNINGS + 1))
}

print_header "🚀 Cloudflare DNS Management - Environment Setup & Validation"
echo ""

# Check 1: Required tools
print_step "Checking required tools..."

# Check Terraform
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -n1 | cut -d' ' -f2 | sed 's/v//')
    print_success "Terraform found: $TERRAFORM_VERSION"
    
    # Check version requirement
    REQUIRED_VERSION="1.0.0"
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$TERRAFORM_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        print_success "Terraform version meets requirements (>= $REQUIRED_VERSION)"
    else
        print_failure "Terraform version $TERRAFORM_VERSION is below required $REQUIRED_VERSION"
        add_error
    fi
else
    print_failure "Terraform not found"
    add_error
    if [ "$FIX_MODE" = true ]; then
        print_info "Installing Terraform..."
        # Add installation commands based on OS
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            print_info "Please install Terraform manually: https://learn.hashicorp.com/tutorials/terraform/install-cli"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew tap hashicorp/tap && brew install hashicorp/tap/terraform
            else
                print_info "Please install Terraform manually: https://learn.hashicorp.com/tutorials/terraform/install-cli"
            fi
        fi
    fi
fi

# Check jq
if command -v jq &> /dev/null; then
    JQ_VERSION=$(jq --version | sed 's/jq-//')
    print_success "jq found: $JQ_VERSION"
else
    print_failure "jq not found (required for import-dns.sh)"
    add_error
    if [ "$FIX_MODE" = true ]; then
        print_info "Installing jq..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y jq
            elif command -v yum &> /dev/null; then
                sudo yum install -y jq
            else
                print_warn "Please install jq manually"
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                brew install jq
            else
                print_warn "Please install jq manually"
            fi
        fi
    fi
fi

# Check curl
if command -v curl &> /dev/null; then
    CURL_VERSION=$(curl --version | head -n1 | cut -d' ' -f2)
    print_success "curl found: $CURL_VERSION"
else
    print_failure "curl not found (required for import-dns.sh)"
    add_error
fi

# Check git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    print_success "git found: $GIT_VERSION"
else
    print_failure "git not found"
    add_error
fi

# Check GitHub CLI (optional)
if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -n1 | cut -d' ' -f3)
    print_success "GitHub CLI found: $GH_VERSION"
else
    print_warn "GitHub CLI not found (optional, but recommended for PR workflow)"
    add_warning
fi

echo ""

# Check 2: Cloudflare configuration (hybrid approach)
print_step "Checking Cloudflare configuration..."

# Check API Token - Environment variable first, then tfvars fallback
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    print_success "CLOUDFLARE_API_TOKEN found in environment variables"
    TOKEN_SOURCE="environment"
elif [ -f "shared/terraform.tfvars" ]; then
    # Extract token from tfvars file
    CLOUDFLARE_API_TOKEN=$(grep 'cloudflare_api_token' shared/terraform.tfvars | cut -d'"' -f2 2>/dev/null)
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        print_success "CLOUDFLARE_API_TOKEN found in shared/terraform.tfvars"
        TOKEN_SOURCE="tfvars"
    fi
fi

if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    # Validate token format (should be 40 characters)
    if [ ${#CLOUDFLARE_API_TOKEN} -eq 40 ]; then
        print_success "API token format appears valid ($TOKEN_SOURCE)"
    else
        print_warn "API token length unusual (expected 40 characters, got ${#CLOUDFLARE_API_TOKEN}) from $TOKEN_SOURCE"
        add_warning
    fi
else
    print_failure "CLOUDFLARE_API_TOKEN not found"
    add_error
    print_info "Set it with: export CLOUDFLARE_API_TOKEN=\"your_token_here\""
    print_info "Or add to shared/terraform.tfvars: cloudflare_api_token = \"your_token_here\""
fi

# Check Account ID - Environment variable first, then tfvars fallback
if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
    print_success "CLOUDFLARE_ACCOUNT_ID found in environment variables"
    ACCOUNT_SOURCE="environment"
elif [ -f "shared/terraform.tfvars" ]; then
    # Extract account ID from tfvars file
    CLOUDFLARE_ACCOUNT_ID=$(grep 'cloudflare_account_id' shared/terraform.tfvars | cut -d'"' -f2 2>/dev/null)
    if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
        print_success "CLOUDFLARE_ACCOUNT_ID found in shared/terraform.tfvars"
        ACCOUNT_SOURCE="tfvars"
    fi
fi

if [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
    # Validate account ID format (should be 32 hex characters)
    if [[ "$CLOUDFLARE_ACCOUNT_ID" =~ ^[a-f0-9]{32}$ ]]; then
        print_success "Account ID format appears valid ($ACCOUNT_SOURCE)"
    else
        print_warn "Account ID format unusual (expected 32 hex characters) from $ACCOUNT_SOURCE"
        add_warning
    fi
else
    print_failure "CLOUDFLARE_ACCOUNT_ID not found"
    add_error
    print_info "Set it with: export CLOUDFLARE_ACCOUNT_ID=\"your_account_id_here\""
    print_info "Or add to shared/terraform.tfvars: cloudflare_account_id = \"your_account_id_here\""
fi

echo ""

# Check 3: API connectivity
print_step "Testing Cloudflare API connectivity..."

if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    print_info "Testing API token..."
    
    # Test API connectivity
    API_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/tokens/verify" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" || echo -e "\n000")
    
    HTTP_CODE=$(echo "$API_RESPONSE" | tail -n1)
    API_BODY=$(echo "$API_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        if echo "$API_BODY" | jq -e '.success' >/dev/null 2>&1; then
            print_success "API token is valid and working"
            
            # Get token info
            TOKEN_STATUS=$(echo "$API_BODY" | jq -r '.result.status' 2>/dev/null || echo "unknown")
            print_info "Token status: $TOKEN_STATUS"
        else
            print_failure "API token validation failed"
            add_error
            echo "$API_BODY" | jq '.errors' 2>/dev/null || echo "$API_BODY"
        fi
    else
        print_failure "API connectivity test failed (HTTP $HTTP_CODE)"
        add_error
        if [ "$HTTP_CODE" = "000" ]; then
            print_error "Could not connect to Cloudflare API (network issue?)"
        fi
    fi
else
    print_warn "Skipping API test (no token set)"
fi

echo ""

# Check 4: Account access (optional for DNS-scoped tokens)
print_step "Testing account access..."

if [ -n "$CLOUDFLARE_API_TOKEN" ] && [ -n "$CLOUDFLARE_ACCOUNT_ID" ]; then
    print_info "Testing account access (optional for DNS-scoped tokens)..."
    
    ACCOUNT_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" || echo -e "\n000")
    
    HTTP_CODE=$(echo "$ACCOUNT_RESPONSE" | tail -n1)
    ACCOUNT_BODY=$(echo "$ACCOUNT_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        if echo "$ACCOUNT_BODY" | jq -e '.success' >/dev/null 2>&1; then
            ACCOUNT_NAME=$(echo "$ACCOUNT_BODY" | jq -r '.result.name' 2>/dev/null || echo "Unknown")
            print_success "Account access confirmed: $ACCOUNT_NAME"
        else
            print_warn "Account access failed (DNS-scoped tokens don't need account permissions)"
            add_warning
        fi
    elif [ "$HTTP_CODE" = "403" ]; then
        print_warn "Account access forbidden (expected for DNS-scoped tokens)"
        print_info "This is normal - DNS tokens don't require account read permissions"
    else
        print_warn "Account access test failed (HTTP $HTTP_CODE) - acceptable for DNS-scoped tokens"
        add_warning
    fi
else
    print_warn "Skipping account test (missing credentials)"
fi

echo ""

# Check 5: Repository structure
print_step "Checking repository structure..."

REQUIRED_DIRS=("modules/zone" "modules/dns" "shared" "scripts")
REQUIRED_FILES=("modules/zone/main.tf" "modules/dns/main.tf" "shared/provider.tf" "scripts/new-domain.sh")

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Directory exists: $dir"
    else
        print_failure "Missing directory: $dir"
        add_error
    fi
done

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_success "File exists: $file"
    else
        print_failure "Missing file: $file"
        add_error
    fi
done

# Check script permissions
SCRIPTS=("scripts/new-domain.sh" "scripts/import-dns.sh" "scripts/setup.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            print_success "Script is executable: $script"
        else
            print_warn "Script not executable: $script"
            add_warning
            if [ "$FIX_MODE" = true ]; then
                chmod +x "$script"
                print_info "Fixed permissions for $script"
            fi
        fi
    fi
done

echo ""

# Check 6: Terraform configuration validation
print_step "Validating Terraform configurations..."

# Check module configurations
for module in "modules/zone" "modules/dns"; do
    if [ -d "$module" ]; then
        print_info "Validating $module..."
        
        # Initialize module if .terraform directory doesn't exist
        if [ ! -d "$module/.terraform" ]; then
            print_info "Initializing $module (first time setup)..."
            if (cd "$module" && terraform init) &>/dev/null; then
                print_success "Module initialized: $module"
            else
                print_warn "Module initialization failed: $module (continuing with validation)"
                add_warning
            fi
        fi
        
        # Validate module
        if (cd "$module" && terraform validate) &>/dev/null; then
            print_success "Module validation passed: $module"
        else
            print_failure "Module validation failed: $module"
            add_error
            # Show the actual error
            print_info "Validation error details:"
            (cd "$module" && terraform validate) 2>&1 | head -5
        fi
    fi
done

echo ""

# Check 7: Example domain configuration
print_step "Checking example domain configuration..."

EXAMPLE_DOMAIN="domains/iamfranco"
if [ -d "$EXAMPLE_DOMAIN" ]; then
    print_success "Example domain family exists: $EXAMPLE_DOMAIN"
    
    # Check required files
    DOMAIN_FILES=("backend.tf" "main.tf" "outputs.tf" "iamfranco-com/main.tf" "iamfranco-com/variables.tf" "iamfranco-com/terraform.tfvars")
    for file in "${DOMAIN_FILES[@]}"; do
        if [ -f "$EXAMPLE_DOMAIN/$file" ]; then
            print_success "Domain file exists: $file"
        else
            print_failure "Missing domain file: $file"
            add_error
        fi
    done
else
    print_failure "Example domain family missing: $EXAMPLE_DOMAIN"
    add_error
fi

echo ""

# Summary
print_header "📊 Setup Validation Summary"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "✅ All checks passed! Your environment is ready for Cloudflare DNS management."
    echo ""
    print_info "🚀 Next steps:"
    print_info "1. Review and update domains/iamfranco/iamfranco-com/terraform.tfvars"
    print_info "2. Test with: cd domains/iamfranco && terraform init && terraform plan"
    print_info "3. Create new domains with: ./scripts/new-domain.sh family-name domain-name"
    echo ""
elif [ $ERRORS -eq 0 ]; then
    print_warn "⚠️  Setup completed with $WARNINGS warning(s). Environment should work but consider addressing warnings."
    echo ""
else
    print_error "❌ Setup validation failed with $ERRORS error(s) and $WARNINGS warning(s)."
    print_error "Please fix the errors before proceeding."
    echo ""
    if [ "$FIX_MODE" = false ]; then
        print_info "💡 Run './scripts/setup.sh --fix' to attempt automatic fixes"
    fi
    exit 1
fi

# Generate environment file template
if [ ! -f ".env.example" ]; then
    print_info "Creating .env.example template..."
    cat > .env.example << 'EOF'
# Cloudflare API Configuration
# Copy this file to .env and fill in your actual values
# Then run: source .env

# Get your API token from: https://dash.cloudflare.com/profile/api-tokens
export CLOUDFLARE_API_TOKEN="your_api_token_here"

# Get your Account ID from: https://dash.cloudflare.com/ (right sidebar)
export CLOUDFLARE_ACCOUNT_ID="your_account_id_here"

# Optional: Terraform Cloud Organization (update in backend.tf files)
export TF_CLOUD_ORGANIZATION="your-terraform-cloud-org"
EOF
    print_success "Created .env.example template"
fi

print_info "🔧 Available scripts:"
print_info "  ./scripts/setup.sh           - Environment validation (this script)"
print_info "  ./scripts/new-domain.sh      - Create new domain configuration"
print_info "  ./scripts/import-dns.sh      - Import existing DNS records"
echo ""

print_info "📚 Documentation:"
print_info "  claude.md                     - Complete implementation guide"
print_info "  README.md                     - Quick start guide"
print_info "  shared/backend.tf             - Terraform Cloud workspace template"