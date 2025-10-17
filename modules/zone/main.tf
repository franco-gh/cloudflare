# Zone Management Module
# Creates and manages a Cloudflare zone with associated settings

resource "cloudflare_zone" "main" {
  account = {
    id = var.account_id
  }
  name = var.domain_name
  type = "full"
}

# Zone settings configuration using individual zone_setting resources (v5+ syntax)
# SSL/TLS settings
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "ssl"
  value      = var.ssl_mode
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "always_use_https"
  value      = var.always_use_https ? "on" : "off"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "min_tls_version"
  value      = var.min_tls_version
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "automatic_https_rewrites"
  value      = var.automatic_https_rewrites ? "on" : "off"
}

# Security settings
resource "cloudflare_zone_setting" "security_level" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "security_level"
  value      = var.security_level
}

resource "cloudflare_zone_setting" "challenge_ttl" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "challenge_ttl"
  value      = var.challenge_ttl
}

resource "cloudflare_zone_setting" "browser_check" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "browser_check"
  value      = var.browser_check
}

# Performance settings
resource "cloudflare_zone_setting" "brotli" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "brotli"
  value      = var.brotli
}

resource "cloudflare_zone_setting" "minify" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "minify"
  value = jsonencode({
    css  = var.minify_css ? "on" : "off"
    html = var.minify_html ? "on" : "off"
    js   = var.minify_js ? "on" : "off"
  })
}

resource "cloudflare_zone_setting" "development_mode" {
  zone_id    = cloudflare_zone.main.id
  setting_id = "development_mode"
  value      = var.development_mode ? "on" : "off"
}

# DNSSEC configuration (optional) - Modern syntax
resource "cloudflare_zone_dnssec" "main" {
  count  = var.enable_dnssec ? 1 : 0
  zone_id = cloudflare_zone.main.id
  status  = "active"
}