# DNS Records Module
# Creates and manages DNS records for a given zone

resource "cloudflare_dns_record" "records" {
  for_each = var.dns_records

  zone_id = var.zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = each.value.proxied

  # Optional fields for specific record types
  priority = each.value.priority

  # Add comment if provided
  comment = each.value.comment

  # Lifecycle management
  lifecycle {
    # Prevent accidental deletion of critical records
    prevent_destroy = false
  }
}

# Optional: Create DNSSEC records if needed
resource "cloudflare_dns_record" "dnssec_records" {
  for_each = var.dnssec_records

  zone_id = var.zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = each.value.ttl
  proxied = false # DNSSEC records cannot be proxied

  comment = "DNSSEC record managed by Terraform"
}