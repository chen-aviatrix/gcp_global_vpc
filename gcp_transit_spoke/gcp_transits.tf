# --------------------------------------------------------------------------- #
# GCP transit gateway stp539-tr-e1 in existing VPC stp539-vpc-tr-e1 (us-east1)
# Primary + HA gateway
# --------------------------------------------------------------------------- #

module "stp539_transit_e1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "~> 2.5"

  cloud   = "GCP"
  name    = "stp539-tr-e1"
  account = aviatrix_account.gcp.account_name
  region  = "us-east1"

  # HA gateway
  ha_gw = true

  # Deploy into the existing VPC created earlier
  use_existing_vpc = true
  vpc_id           = aviatrix_vpc.stp539_vpc_tr_e1.vpc_id
  gw_subnet        = local.gcp_vpc_tr_e1_subnets[0].cidr # 10.3.0.0/24 in us-east1
  hagw_subnet      = local.gcp_vpc_tr_e1_subnets[1].cidr # 10.3.1.0/24 in us-east1
}
