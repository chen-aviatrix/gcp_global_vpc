module "spoke_onprem0" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud           = "AWS"
  name            = "onprem0"
  region          = "us-east-1"
  cidr            = "192.168.3.0/24"
  account         = var.aviatrix_aws_account
  ha_gw           = false # single gateway in the group
  attached        = false
  enable_bgp      = true
  local_as_number = "5100"
}

module "spoke_onprem_e1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud           = "AWS"
  name            = "onprem-e1"
  region          = "us-east-1"
  cidr            = "192.168.1.0/24"
  account         = var.aviatrix_aws_account
  ha_gw           = true
  single_az_ha    = false
  attached        = false
  enable_bgp      = true
  local_as_number = "5001"
}

resource "aviatrix_transit_external_device_conn" "t1_to_onprem1" {
  vpc_id            = module.transit_aws_t1.vpc.vpc_id
  connection_name   = "t1-to-onpreme1"
  gw_name           = module.transit_aws_t1.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "65001"
  bgp_remote_as_num = "5001"
  remote_gateway_ip = module.spoke_onprem_e1.spoke_gateway.eip
  local_tunnel_cidr = "169.254.100.1/30,169.254.100.5/30"
  remote_tunnel_cidr = "169.254.100.2/30,169.254.100.6/30"
 
  ha_enabled               = true
  backup_bgp_remote_as_num = "5001"
  backup_remote_gateway_ip = module.spoke_onprem_e1.spoke_gateway.ha_public_ip
  backup_local_tunnel_cidr = "169.254.100.9/30,169.254.100.13/30"
  backup_remote_tunnel_cidr = "169.254.100.10/30,169.254.100.14/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [module.transit_aws_t1, module.spoke_onprem_e1]
}

resource "aviatrix_transit_external_device_conn" "onprem1_to_t1" {
  vpc_id            = module.spoke_onprem_e1.vpc.vpc_id
  connection_name   = "onpreme1-to-t1"
  gw_name           = module.spoke_onprem_e1.spoke_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "5001"
  bgp_remote_as_num = "65001"
  remote_gateway_ip = module.transit_aws_t1.transit_gateway.eip
  local_tunnel_cidr = "169.254.100.2/30,169.254.100.10/30"
  remote_tunnel_cidr = "169.254.100.1/30,169.254.100.9/30"

  ha_enabled               = true
  backup_bgp_remote_as_num = "65001"
  backup_remote_gateway_ip = module.transit_aws_t1.transit_gateway.ha_public_ip
  backup_local_tunnel_cidr = "169.254.100.6/30,169.254.100.14/30"
  backup_remote_tunnel_cidr = "169.254.100.5/30,169.254.100.13/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [aviatrix_transit_external_device_conn.t1_to_onprem1]
}

module "spoke_onprem_w1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud           = "AWS"
  name            = "onprem-w1"
  region          = var.aws_region
  cidr            = "192.168.2.0/24"
  account         = var.aviatrix_aws_account
  ha_gw           = true
  single_az_ha    = false
  attached        = false
  enable_bgp      = true
  local_as_number = "5002"

  spoke_bgp_manual_advertise_cidrs = ["2.2.2.2/32"]
}

resource "aviatrix_transit_external_device_conn" "t2_to_onprem_w1" {
  vpc_id            = module.transit_aws_t2.vpc.vpc_id
  connection_name   = "t2-to-onpremw1"
  gw_name           = module.transit_aws_t2.transit_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "65002"
  bgp_remote_as_num = "5002"
  remote_gateway_ip = module.spoke_onprem_w1.spoke_gateway.eip
  local_tunnel_cidr = "169.254.100.1/30,169.254.100.5/30"
  remote_tunnel_cidr = "169.254.100.2/30,169.254.100.6/30"

  ha_enabled               = true
  backup_bgp_remote_as_num = "5002"
  backup_remote_gateway_ip = module.spoke_onprem_w1.spoke_gateway.ha_public_ip
  backup_local_tunnel_cidr = "169.254.100.9/30,169.254.100.13/30"
  backup_remote_tunnel_cidr = "169.254.100.10/30,169.254.100.14/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [module.transit_aws_t2, module.spoke_onprem_w1]
}

resource "aviatrix_transit_external_device_conn" "onprem_w1_to_t2" {
  vpc_id            = module.spoke_onprem_w1.vpc.vpc_id
  connection_name   = "onpremw1-to-t2"
  gw_name           = module.spoke_onprem_w1.spoke_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "5002"
  bgp_remote_as_num = "65002"
  remote_gateway_ip = module.transit_aws_t2.transit_gateway.eip
  local_tunnel_cidr = "169.254.100.2/30,169.254.100.10/30"
  remote_tunnel_cidr = "169.254.100.1/30,169.254.100.9/30"

  ha_enabled               = true
  backup_bgp_remote_as_num = "65002"
  backup_remote_gateway_ip = module.transit_aws_t2.transit_gateway.ha_public_ip
  backup_local_tunnel_cidr = "169.254.100.6/30,169.254.100.14/30"
  backup_remote_tunnel_cidr = "169.254.100.5/30,169.254.100.13/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [aviatrix_transit_external_device_conn.t2_to_onprem_w1]
}

locals {
  # GCP transit gateway public IPs (primary + HA) for onprem s2c connections
  tr_w1_ip   = "136.67.23.107"
  tr_w1_haip = "34.127.108.85"
  tr_e1_ip   = "34.26.54.31"
  tr_e1_haip = "34.74.59.251"
}
resource "aviatrix_transit_external_device_conn" "onprem_w1_to_remote_tr_w1" {
  vpc_id            = module.spoke_onprem_w1.vpc.vpc_id
  connection_name   = "onpremw1-to-tr-w1"
  gw_name           = module.spoke_onprem_w1.spoke_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "5002"
  bgp_remote_as_num = "65102"
  remote_gateway_ip = local.tr_w1_ip
  local_tunnel_cidr = "169.254.200.2/30,169.254.200.10/30"
  remote_tunnel_cidr = "169.254.200.1/30,169.254.200.9/30"

  ha_enabled               = true
  backup_bgp_remote_as_num = "65102"
  backup_remote_gateway_ip = local.tr_w1_haip
  backup_local_tunnel_cidr = "169.254.200.6/30,169.254.200.14/30"
  backup_remote_tunnel_cidr = "169.254.200.5/30,169.254.200.13/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [aviatrix_transit_external_device_conn.t2_to_onprem_w1]
}

resource "aviatrix_transit_external_device_conn" "onprem_e1_to_remote_tr_e1" {
  vpc_id            = module.spoke_onprem_e1.vpc.vpc_id
  connection_name   = "onpreme1-to-tr-e1"
  gw_name           = module.spoke_onprem_e1.spoke_gateway.gw_name
  connection_type   = "bgp"
  tunnel_protocol   = "IPsec"
  bgp_local_as_num  = "5001"
  bgp_remote_as_num = "65101"
  remote_gateway_ip = local.tr_e1_ip
  local_tunnel_cidr = "169.254.200.2/30,169.254.200.10/30"
  remote_tunnel_cidr = "169.254.200.1/30,169.254.200.9/30"

  ha_enabled               = true
  backup_bgp_remote_as_num = "65101"
  backup_remote_gateway_ip = local.tr_e1_haip
  backup_local_tunnel_cidr = "169.254.200.6/30,169.254.200.14/30"
  backup_remote_tunnel_cidr = "169.254.200.5/30,169.254.200.13/30"

  pre_shared_key        = "avx"
  backup_pre_shared_key = "avx"

  depends_on = [aviatrix_transit_external_device_conn.t1_to_onprem1]
}
