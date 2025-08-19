# Zone Management Module
# Creates and manages a Cloudflare zone with associated settings

resource "cloudflare_zone" "main" {
  zone = var.domain_name
  plan = var.zone_plan
  type = "full"
}

# Zone settings configuration
resource "cloudflare_zone_settings_override" "main" {
  zone_id = cloudflare_zone.main.id

  settings {
    # SSL/TLS settings
    ssl                      = var.ssl_mode
    always_use_https        = var.always_use_https
    min_tls_version         = var.min_tls_version
    automatic_https_rewrites = var.automatic_https_rewrites

    # Security settings
    security_level          = var.security_level
    challenge_ttl          = var.challenge_ttl
    browser_check          = var.browser_check

    # Performance settings
    brotli                 = var.brotli
    minify {
      css  = var.minify_css
      html = var.minify_html
      js   = var.minify_js
    }

    # Development mode
    development_mode = var.development_mode
  }
}

# DNSSEC configuration (optional)
resource "cloudflare_zone_dnssec" "main" {
  count   = var.enable_dnssec ? 1 : 0
  zone_id = cloudflare_zone.main.id
}