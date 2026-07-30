# --------------------------------------------------------------------------- #
# GCP transit gateway tr-e1 in existing VPC vpc-tr-e1 (us-east1)
# Primary + HA gateway
# --------------------------------------------------------------------------- #

module "transit_e1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "~> 2.5"

  cloud   = "GCP"
  name    = "${var.TB_prefix}-tr-e1"
  account = aviatrix_account.gcp.account_name
  region  = "us-east1"

  # Smallest Aviatrix-supported GCP gateway size
  instance_size = "n1-standard-1"

  # HA gateway
  ha_gw        = true
  single_az_ha = false

  # Deploy into the existing VPC created earlier
  use_existing_vpc = true
  vpc_id           = aviatrix_vpc.vpc_tr_e1.vpc_id
  gw_subnet        = local.gcp_vpc_tr_e1_subnets[0].cidr # 10.3.0.0/24 in us-east1
  hagw_subnet      = local.gcp_vpc_tr_e1_subnets[1].cidr # 10.3.1.0/24 in us-east1
}

# --------------------------------------------------------------------------- #
# GCP transit gateway tr-w1 in existing VPC vpc-tr-w1 (us-west1)
# Primary + HA gateway, HPE (insane mode)
# --------------------------------------------------------------------------- #

module "transit_w1" {
  source  = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version = "~> 2.5"

  cloud   = "GCP"
  name    = "${var.TB_prefix}-tr-w1"
  account = aviatrix_account.gcp.account_name
  region  = "us-west1"

  # HA gateway
  ha_gw        = true
  single_az_ha = false

  # HPE (insane mode)
  insane_mode = true

  # Smallest HPE-supported GCP gateway size
  instance_size = "n1-highcpu-4"

  # Deploy into the existing VPC created earlier
  use_existing_vpc = true
  vpc_id           = aviatrix_vpc.vpc_tr_w1.vpc_id
  gw_subnet        = local.gcp_vpc_tr_w1_subnets[0].cidr # 10.4.0.0/24 in us-west1
  hagw_subnet      = local.gcp_vpc_tr_w1_subnets[1].cidr # 10.4.1.0/24 in us-west1
}
