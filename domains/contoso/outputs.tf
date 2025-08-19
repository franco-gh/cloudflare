# contoso Domain Family Outputs

output "contoso-com" {
  description = "contoso.com domain details"
  value = {
    zone_id      = module.contoso-com.zone_id
    nameservers  = module.contoso-com.nameservers
    zone_status  = module.contoso-com.zone_status
    dns_records  = module.contoso-com.dns_records
  }
}

output "contoso-net" {
  description = "contoso.net domain details"
  value = {
    zone_id      = module.contoso-net.zone_id
    nameservers  = module.contoso-net.nameservers
    zone_status  = module.contoso-net.zone_status
    dns_records  = module.contoso-net.dns_records
  }
}

output "contoso-co" {
  description = "contoso.co domain details"
  value = {
    zone_id      = module.contoso-co.zone_id
    nameservers  = module.contoso-co.nameservers
    zone_status  = module.contoso-co.zone_status
    dns_records  = module.contoso-co.dns_records
  }
}
