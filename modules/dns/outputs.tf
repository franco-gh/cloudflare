# DNS Module Outputs

output "record_details" {
  description = "Details of all created DNS records"
  value = {
    for k, v in cloudflare_dns_record.records : k => {
      zone_id       = v.zone_id
      name     = v.name
      content  = v.content
      type     = v.type
      ttl      = v.ttl
      proxied  = v.proxied
      priority = v.priority
      comment  = v.comment
      # hostname = v.hostname
      meta = v.meta
    }
      }
}

output "record_fqdns" {
  description = "Fully qualified domain names of created records"
  value = {
    for k, v in cloudflare_dns_record.records : k => v.name
  }
}

output "record_ids" {
  description = "IDs of all created DNS records"
  value = {
    for k, v in cloudflare_dns_record.records : k => v.id
  }
}

output "proxied_records" {
  description = "List of records that are proxied through Cloudflare"
  value = {
    for k, v in cloudflare_dns_record.records : k => v.proxied if v.proxied == true
  }
}

output "a_records" {
  description = "A record details (IP addresses)"
  value = {
    for k, v in cloudflare_dns_record.records : k => {
      name = v.name
      content  = v.content
    } if v.type == "A"
  }
}

output "cname_records" {
  description = "CNAME record details"
  value = {
    for k, v in cloudflare_dns_record.records : k => {
      name = v.name
      content  = v.content
    } if v.type == "CNAME"
  }
}

output "mx_records" {
  description = "MX record details"
  value = {
    for k, v in cloudflare_dns_record.records : k => {
      name = v.name
      content  = v.content
      priority = v.priority
    } if v.type == "MX"
  }
}

output "txt_records" {
  description = "TXT record details"
  value = {
    for k, v in cloudflare_dns_record.records : k => {
      name = v.name
      content  = v.content
    } if v.type == "TXT"
  }
}

output "dnssec_record_details" {
  description = "Details of DNSSEC-related records"
  value = {
    for k, v in cloudflare_dns_record.dnssec_records : k => {
      id      = v.id
      name    = v.name
      content = v.content
      type    = v.type
      ttl     = v.ttl
    }
  }
}