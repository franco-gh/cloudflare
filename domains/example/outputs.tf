# example Domain Family Outputs

output "example-com" {
  description = "example.com domain details"
  value = {
    zone_id      = module.example-com.zone_id
    nameservers  = module.example-com.nameservers
    zone_status  = module.example-com.zone_status
    dns_records  = module.example-com.dns_records
  }
}

output "example-net" {
  description = "example.net domain details"
  value = {
    zone_id      = module.example-net.zone_id
    nameservers  = module.example-net.nameservers
    zone_status  = module.example-net.zone_status
    dns_records  = module.example-net.dns_records
  }
}

output "example-co" {
  description = "example.co domain details"
  value = {
    zone_id      = module.example-co.zone_id
    nameservers  = module.example-co.nameservers
    zone_status  = module.example-co.zone_status
    dns_records  = module.example-co.dns_records
  }
}
