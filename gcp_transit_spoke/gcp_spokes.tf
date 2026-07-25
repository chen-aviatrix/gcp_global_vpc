# --------------------------------------------------------------------------- #
# GCP spoke stp539-spoke-e1 in existing VPC stp539-vpc-us (us-east1)
# Unattached (no GCP transit gateway exists yet)
# --------------------------------------------------------------------------- #

module "stp539_spoke_e1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud    = "GCP"
  name     = "stp539-spoke-e1"
  account  = aviatrix_account.gcp.account_name
  region   = "us-east1"
  attached = false

  # Gateway group: 1 primary + 2 HA gateways
  ha_gw           = true
  group_mode      = true
  spoke_gw_amount = 3

  # Enable GCP global VPC mode
  enable_global_vpc = true

  # Deploy into the existing VPC created earlier
  use_existing_vpc = true
  vpc_id           = aviatrix_vpc.stp539_vpc_us.vpc_id
  gw_subnet        = local.gcp_vpc_subnets[0].cidr # 10.10.0.0/24 in us-east1
  hagw_subnet      = local.gcp_vpc_subnets[1].cidr # 10.10.1.0/24 in us-east1

  # Subnets for the additional group-mode gateways
  additional_group_mode_subnets = [
    local.gcp_vpc_subnets[2].cidr, # 10.10.2.0/24 in us-east1
  ]
}

# --------------------------------------------------------------------------- #
# GCP spoke stp539-spoke-w1 in existing VPC stp539-vpc-us (us-west1)
# Unattached (no GCP transit gateway exists yet)
# --------------------------------------------------------------------------- #

module "stp539_spoke_w1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud    = "GCP"
  name     = "stp539-spoke-w1"
  account  = aviatrix_account.gcp.account_name
  region   = "us-west1"
  attached = false

  # Gateway group: 1 primary + 2 HA gateways
  ha_gw           = true
  group_mode      = true
  spoke_gw_amount = 3

  # Enable GCP global VPC mode
  enable_global_vpc = true

  # Deploy into the existing VPC created earlier
  use_existing_vpc = true
  vpc_id           = aviatrix_vpc.stp539_vpc_us.vpc_id
  gw_subnet        = local.gcp_vpc_subnets[4].cidr # 10.10.128.0/24 in us-west1
  hagw_subnet      = local.gcp_vpc_subnets[5].cidr # 10.10.129.0/24 in us-west1

  # Subnets for the additional group-mode gateways
  additional_group_mode_subnets = [
    local.gcp_vpc_subnets[6].cidr, # 10.10.130.0/24 in us-west1
  ]
}
