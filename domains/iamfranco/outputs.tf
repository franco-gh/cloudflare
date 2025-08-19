# iamfranco Domain Family Outputs

output "iamfranco_com" {
  description = "iamfranco.com domain details"
  value = {
    zone_id      = module.iamfranco_com.zone_id
    nameservers  = module.iamfranco_com.nameservers
    zone_status  = module.iamfranco_com.zone_status
    dns_records  = module.iamfranco_com.dns_records
  }
}