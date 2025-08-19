# Zone Module Outputs

output "zone_id" {
  description = "The zone ID"
  value       = cloudflare_zone.main.id
}

output "zone_name" {
  description = "The zone name"
  value       = cloudflare_zone.main.zone
}

output "name_servers" {
  description = "Cloudflare nameservers for this zone"
  value       = cloudflare_zone.main.name_servers
}

output "status" {
  description = "Zone status"
  value       = cloudflare_zone.main.status
}

output "verification_key" {
  description = "Zone verification key"
  value       = cloudflare_zone.main.verification_key
  sensitive   = true
}

output "plan" {
  description = "Zone plan"
  value       = cloudflare_zone.main.plan
}

output "vanity_name_servers" {
  description = "Vanity nameservers (if available)"
  value       = cloudflare_zone.main.vanity_name_servers
}

output "meta" {
  description = "Zone metadata"
  value       = cloudflare_zone.main.meta
}