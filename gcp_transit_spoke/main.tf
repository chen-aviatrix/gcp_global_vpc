# --------------------------------------------------------------------------- #
# Transit gateway t1 (us-west-1) with HA
# --------------------------------------------------------------------------- #

module "transit_aws_t1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "~> 2.5"

  cloud         = "AWS"
  name          = "t1"
  region        = "us-east-1"
  cidr          = "10.1.0.0/16"
  account       = var.aviatrix_aws_account
  ha_gw         = true
  local_as_number = "65001"
}

# --------------------------------------------------------------------------- #
# Transit gateway t2 (us-west-1) with HA, HPE (insane mode)
# --------------------------------------------------------------------------- #

module "transit_aws_t2" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "~> 2.5"

  cloud           = "AWS"
  name            = "t2"
  region          = var.aws_region
  cidr            = "10.2.0.0/16"
  account         = var.aviatrix_aws_account
  ha_gw           = true
  insane_mode     = true
  az2             = "c"
  local_as_number = "65002"
}

# --------------------------------------------------------------------------- #
# spoke1: 4-gateway group (1 primary + 3 HA), attached to transit t1
# --------------------------------------------------------------------------- #

module "spoke1" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud           = "AWS"
  name            = "spoke1"
  region          = "us-east-1"
  cidr            = "10.11.0.0/16"
  account         = var.aviatrix_aws_account
  ha_gw           = true
  transit_gw      = module.transit_aws_t1.transit_gateway.gw_name
  group_mode      = true
  spoke_gw_amount = 4
}

# --------------------------------------------------------------------------- #
# spoke2: HPE, 3-gateway group (1 primary + 2 HA), attached to transit t2
# --------------------------------------------------------------------------- #

module "spoke2" {
  source  = "terraform-aviatrix-modules/mc-spoke/aviatrix"
  version = "~> 1.6"

  cloud       = "AWS"
  name        = "spoke2"
  region      = var.aws_region
  cidr        = "10.22.0.0/16"
  account     = var.aviatrix_aws_account
  ha_gw       = true
  insane_mode = true
  az2         = "c"
  transit_gw  = module.transit_aws_t2.transit_gateway.gw_name
}
