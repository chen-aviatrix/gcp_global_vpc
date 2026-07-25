output "transit_t1_gateway_name" {
  value = module.transit_aws_t1.transit_gateway.gw_name
}

output "transit_t1_ha_gateway_name" {
  value = module.transit_aws_t1.transit_gateway.ha_gw_name
}

output "transit_t1_vpc_id" {
  value = module.transit_aws_t1.vpc.vpc_id
}

output "transit_t2_gateway_name" {
  value = module.transit_aws_t2.transit_gateway.gw_name
}

output "transit_t2_vpc_id" {
  value = module.transit_aws_t2.vpc.vpc_id
}

output "onprem_e1_gateway_eip" {
  value     = module.spoke_onprem_e1.spoke_gateway.eip
  sensitive = true
}

output "onprem_w1_gateway_eip" {
  value     = module.spoke_onprem_w1.spoke_gateway.eip
  sensitive = true
}

output "spoke1_gateway_name" {
  value     = module.spoke1.spoke_gateway.gw_name
  sensitive = true
}

output "spoke1_vpc_id" {
  value     = module.spoke1.vpc.vpc_id
  sensitive = true
}

output "spoke2_gateway_name" {
  value     = module.spoke2.spoke_gateway.gw_name
  sensitive = true
}

output "spoke2_vpc_id" {
  value     = module.spoke2.vpc.vpc_id
  sensitive = true
}
