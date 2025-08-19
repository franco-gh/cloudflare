# DNS Module Variables

variable "zone_id" {
  description = "The zone ID where DNS records will be created"
  type        = string
  validation {
    condition     = can(regex("^[a-f0-9]{32}$", var.zone_id))
    error_message = "Zone ID must be a valid 32-character hexadecimal string."
  }
}

variable "dns_records" {
  description = "Map of DNS records to create"
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

  validation {
    condition = alltrue([
      for k, v in var.dns_records : contains([
        "A", "AAAA", "CNAME", "MX", "TXT", "SRV", "NS", "PTR", "CAA", "CERT", "DNSKEY", "DS", "NAPTR", "SMIMEA", "SSHFP", "TLSA", "URI"
      ], v.type)
    ])
    error_message = "DNS record type must be one of the supported Cloudflare record types."
  }
}

variable "dnssec_records" {
  description = "Map of DNSSEC-related DNS records (DS, DNSKEY, etc.)"
  type = map(object({
    type    = string
    name    = string
    content = string
    ttl     = optional(number, 1)
    comment = optional(string)
  }))
  default = {}
}

variable "default_ttl" {
  description = "Default TTL for records that don't specify one"
  type        = number
  default     = 1
  validation {
    condition     = var.default_ttl == 1 || (var.default_ttl >= 120 && var.default_ttl <= 2147483647)
    error_message = "TTL must be 1 (automatic) or between 120 and 2147483647 seconds."
  }
}

variable "enable_proxying" {
  description = "Enable Cloudflare proxying by default for supported record types"
  type        = bool
  default     = false
}