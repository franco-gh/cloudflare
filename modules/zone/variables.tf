# Zone Module Variables

variable "domain_name" {
  description = "The domain name for this zone"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "zone_plan" {
  description = "Cloudflare zone plan"
  type        = string
  default     = "free"
  validation {
    condition     = contains(["free", "pro", "business", "enterprise"], var.zone_plan)
    error_message = "Zone plan must be one of: free, pro, business, enterprise."
  }
}

# SSL/TLS Configuration
variable "ssl_mode" {
  description = "SSL/TLS encryption mode"
  type        = string
  default     = "full"
  validation {
    condition     = contains(["off", "flexible", "full", "strict"], var.ssl_mode)
    error_message = "SSL mode must be one of: off, flexible, full, strict."
  }
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
  validation {
    condition     = contains(["1.0", "1.1", "1.2", "1.3"], var.min_tls_version)
    error_message = "TLS version must be one of: 1.0, 1.1, 1.2, 1.3."
  }
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
  validation {
    condition     = contains(["off", "essentially_off", "low", "medium", "high", "under_attack"], var.security_level)
    error_message = "Security level must be one of: off, essentially_off, low, medium, high, under_attack."
  }
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
  validation {
    condition     = contains(["on", "off"], var.browser_check)
    error_message = "Browser check must be either 'on' or 'off'."
  }
}

# Performance Configuration
variable "brotli" {
  description = "Enable Brotli compression"
  type        = string
  default     = "on"
  validation {
    condition     = contains(["on", "off"], var.brotli)
    error_message = "Brotli must be either 'on' or 'off'."
  }
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

# Tags
variable "tags" {
  description = "Tags to apply to the zone"
  type        = map(string)
  default     = {}
}