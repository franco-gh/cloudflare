# Shared variables used across all domain families

# Domain Configuration
variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
}

# Common DNS settings
variable "default_ttl" {
  description = "Default TTL for DNS records (1 = automatic)"
  type        = number
  default     = 1
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    repository = "cloudflare-dns-management"
  }
}

# Zone settings
variable "default_zone_plan" {
  description = "Default Cloudflare zone plan"
  type        = string
  default     = "free"
  validation {
    condition     = contains(["free", "pro", "business", "enterprise"], var.default_zone_plan)
    error_message = "Zone plan must be one of: free, pro, business, enterprise."
  }
}