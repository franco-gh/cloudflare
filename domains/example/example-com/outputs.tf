# example.com Domain Outputs

output "zone_id" {
  description = "Zone ID for example.com"
  value       = module.zone.zone_id
}

output "nameservers" {
  description = "Cloudflare nameservers for example.com"
  value       = module.zone.name_servers
}

output "zone_status" {
  description = "Zone status"
  value       = module.zone.status
}

output "verification_key" {
  description = "Zone verification key"
  value       = module.zone.verification_key
  sensitive   = true
}

output "dns_records" {
  description = "Created DNS records"
  value       = module.dns.record_details
}

output "record_fqdns" {
  description = "Fully qualified domain names"
  value       = module.dns.record_fqdns
}

output "a_records" {
  description = "A record details"
  value       = module.dns.a_records
}

output "cname_records" {
  description = "CNAME record details"
  value       = module.dns.cname_records
}

output "mx_records" {
  description = "MX record details"
  value       = module.dns.mx_records
}

output "txt_records" {
  description = "TXT record details"
  value       = module.dns.txt_records
}
