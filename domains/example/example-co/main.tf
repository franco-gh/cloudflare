# example.co Domain Configuration

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
