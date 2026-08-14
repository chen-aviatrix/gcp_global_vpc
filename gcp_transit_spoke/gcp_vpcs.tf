# --------------------------------------------------------------------------- #
# GCP account onboarding on the Aviatrix controller
# --------------------------------------------------------------------------- #

resource "aviatrix_account" "gcp" {
  account_name                        = var.aviatrix_gcp_account
  cloud_type                          = 4 # GCP
  gcloud_project_id                   = var.gcp_project_id
  gcloud_project_credentials_filepath = var.gcp_credentials_file
}

# --------------------------------------------------------------------------- #
# GCP VPC vpc-us (global) with 4 /24 subnets in us-east1 and us-west1
# --------------------------------------------------------------------------- #

locals {
  gcp_vpc_subnets = [
    { region = "us-west1", cidr = "10.10.0.0/24", name = "${var.TB_prefix}-vpc-us-west1-1" },
    { region = "us-west1", cidr = "10.10.1.0/24", name = "${var.TB_prefix}-vpc-us-west1-2" },
    { region = "us-west1", cidr = "10.10.2.0/24", name = "${var.TB_prefix}-vpc-us-west1-3" },
    { region = "us-west1", cidr = "10.10.3.0/24", name = "${var.TB_prefix}-vpc-us-west1-4" },
    { region = "us-east1", cidr = "10.10.128.0/24", name = "${var.TB_prefix}-vpc-us-east1-1" },
    { region = "us-east1", cidr = "10.10.129.0/24", name = "${var.TB_prefix}-vpc-us-east1-2" },
    { region = "us-east1", cidr = "10.10.130.0/24", name = "${var.TB_prefix}-vpc-us-east1-3" },
    { region = "us-east1", cidr = "10.10.131.0/24", name = "${var.TB_prefix}-vpc-us-east1-4" },
  ]
}

resource "aviatrix_vpc" "vpc_us" {
  cloud_type   = 4 # GCP
  account_name = aviatrix_account.gcp.account_name
  name         = "${var.TB_prefix}-vpc-us"

  dynamic "subnets" {
    for_each = local.gcp_vpc_subnets
    content {
      region = subnets.value.region
      cidr   = subnets.value.cidr
      name   = subnets.value.name
    }
  }
}

# --------------------------------------------------------------------------- #
# GCP VPC vpc-tr-e1 (global) with 4 /24 subnets in us-east1
# --------------------------------------------------------------------------- #

locals {
  gcp_vpc_tr_e1_subnets = [
    { region = "us-east1", cidr = "10.3.0.0/24", name = "${var.TB_prefix}-vpc-tr-e1-1" },
    { region = "us-east1", cidr = "10.3.1.0/24", name = "${var.TB_prefix}-vpc-tr-e1-2" },
    { region = "us-east1", cidr = "10.3.2.0/24", name = "${var.TB_prefix}-vpc-tr-e1-3" },
    { region = "us-east1", cidr = "10.3.3.0/24", name = "${var.TB_prefix}-vpc-tr-e1-4" },
  ]
}

resource "aviatrix_vpc" "vpc_tr_e1" {
  cloud_type   = 4 # GCP
  account_name = aviatrix_account.gcp.account_name
  name         = "${var.TB_prefix}-vpc-tr-e1"

  dynamic "subnets" {
    for_each = local.gcp_vpc_tr_e1_subnets
    content {
      region = subnets.value.region
      cidr   = subnets.value.cidr
      name   = subnets.value.name
    }
  }
}

# --------------------------------------------------------------------------- #
# GCP VPC vpc-tr-w1 (global) with 4 /24 subnets in us-west1
# --------------------------------------------------------------------------- #

locals {
  gcp_vpc_tr_w1_subnets = [
    { region = "us-west1", cidr = "10.4.0.0/24", name = "${var.TB_prefix}-vpc-tr-w1-1" },
    { region = "us-west1", cidr = "10.4.1.0/24", name = "${var.TB_prefix}-vpc-tr-w1-2" },
    { region = "us-west1", cidr = "10.4.2.0/24", name = "${var.TB_prefix}-vpc-tr-w1-3" },
    { region = "us-west1", cidr = "10.4.3.0/24", name = "${var.TB_prefix}-vpc-tr-w1-4" },
  ]
}

resource "aviatrix_vpc" "vpc_tr_w1" {
  cloud_type   = 4 # GCP
  account_name = aviatrix_account.gcp.account_name
  name         = "${var.TB_prefix}-vpc-tr-w1"

  dynamic "subnets" {
    for_each = local.gcp_vpc_tr_w1_subnets
    content {
      region = subnets.value.region
      cidr   = subnets.value.cidr
      name   = subnets.value.name
    }
  }
}
