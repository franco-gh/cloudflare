# DNS Records Module
# Creates and manages DNS records for a given zone

resource "cloudflare_dns_record" "records" {
  for_each = var.dns_records

  zone_id = var.zone_id
  name    = each.value.name
  content = each.value.content
  type    = each.value.type
  ttl     = each.value.ttl

  # Conditional proxying - only for supported record types
  proxied = each.value.proxied && contains(["A", "AAAA", "CNAME"], each.value.type) ? each.value.proxied : false

  # Optional fields for specific record types
  priority = each.value.type == "MX" || each.value.type == "SRV" ? each.value.priority : null

  # Add comment if provided
  comment = each.value.comment

  # Lifecycle management
  lifecycle {
    # Prevent accidental deletion of critical records
    prevent_destroy = false

    # Ignore changes to these computed attributes
    ignore_changes = [ttl]
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