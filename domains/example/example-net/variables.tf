# example.net Domain Variables

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "example.net"
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
  description = "DNS records to create for example.net"
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
    domain     = "example.net"
    family     = "example"
    managed_by = "terraform"
  }
}
