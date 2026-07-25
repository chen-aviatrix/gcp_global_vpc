resource "tls_private_key" "terraform_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  filename        = "terraform_key.pem"
  content         = tls_private_key.terraform_key.private_key_pem
  file_permission = "0600"
}

locals {
  prefix        = "stp539"
}

module "aws_onpreme1_vm" {
  source               = "../mc-vm-csp/aws"
  resource_name_label  = "${local.prefix}-onprem-e1-vm"
  providers            = { aws = aws.us_east_1 }
  region               = module.spoke_onprem_e1.vpc.region
  vpc_id               = module.spoke_onprem_e1.vpc.vpc_id
  public_subnet_id     = module.spoke_onprem_e1.vpc.public_subnets[0].subnet_id
  private_subnet_id    = module.spoke_onprem_e1.vpc.private_subnets[0].subnet_id
  ingress_cidrs        = var.ingress_cidrs # List of CIDRs to allow ingress traffic thru SSH/ICMP to the VMs
  use_existing_keypair = true
  public_key           = tls_private_key.terraform_key.public_key_openssh
}

module "aws_onpremw1_vm" {
  source               = "../mc-vm-csp/aws"
  resource_name_label  = "${local.prefix}-onprem-w1-vm"
  providers            = { aws = aws.us_west_1 }
  region               = module.spoke_onprem_w1.vpc.region
  vpc_id               = module.spoke_onprem_w1.vpc.vpc_id
  public_subnet_id     = module.spoke_onprem_w1.vpc.public_subnets[0].subnet_id
  private_subnet_id    = module.spoke_onprem_w1.vpc.private_subnets[0].subnet_id
  ingress_cidrs        = var.ingress_cidrs # List of CIDRs to allow ingress traffic thru SSH/ICMP to the VMs
  use_existing_keypair = true
  public_key           = tls_private_key.terraform_key.public_key_openssh
}

module "gcp_vpc_us_e1_vm1" {
  source               = "../mc-vm-csp/gcp"
  resource_name_label  = "${local.prefix}-us-e1-vm1"
  region               = aviatrix_vpc.stp539_vpc_us.subnets[0].region
  region2              = aviatrix_vpc.stp539_vpc_us.subnets[0].region
  vpc_id               = aviatrix_vpc.stp539_vpc_us.vpc_id
  public_subnet_id     = aviatrix_vpc.stp539_vpc_us.subnets[0].name
  private_subnet_id    = aviatrix_vpc.stp539_vpc_us.subnets[0].name
  ingress_cidrs        = var.ingress_cidrs # List of CIDRs to allow ingress traffic thru SSH/ICMP to the VMs
  use_existing_keypair = true
  public_key           = tls_private_key.terraform_key.public_key_openssh
}

module "gcp_vpc_us_e1_vm2" {
  source               = "../mc-vm-csp/gcp"
  resource_name_label  = "${local.prefix}-us-e1-vm2"
  region               = aviatrix_vpc.stp539_vpc_us.subnets[1].region
  region2              = aviatrix_vpc.stp539_vpc_us.subnets[1].region
  vpc_id               = aviatrix_vpc.stp539_vpc_us.vpc_id
  public_subnet_id     = aviatrix_vpc.stp539_vpc_us.subnets[1].name
  private_subnet_id    = aviatrix_vpc.stp539_vpc_us.subnets[1].name
  ingress_cidrs        = var.ingress_cidrs # List of CIDRs to allow ingress traffic thru SSH/ICMP to the VMs
  use_existing_keypair = true
  public_key           = tls_private_key.terraform_key.public_key_openssh
}

