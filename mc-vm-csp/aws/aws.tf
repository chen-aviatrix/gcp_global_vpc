/*
    VPC-level scope
*/
data "aws_vpc" "vpc" {
  count = local.cloud == "aws" ? 1 : 0
  id    = local.vpc_id
}

// local vars
locals {
  cloud = "aws"

  # Determine "sub" CSP
  is_china = can(regex("^cn-|^china ", lower(var.region))) && contains(["aws", "azure"], local.cloud)            # If a region in Azure or AWS starts with China prefix, then results in true.
  is_gov   = can(regex("^us-gov|^usgov |^usdod ", lower(var.region))) && contains(["aws", "azure"], local.cloud) # If a region in Azure or AWS starts with Gov/DoD prefix, then results in true.

  instance_size = length(var.instance_size) > 0 ? var.instance_size : lookup(local.instance_size_map, local.cloud, null)
  instance_size_map = {
    aws   = "t3.small",
    gcp   = "n1-standard-1",
    azure = "Standard_B1ms",
    oci   = "VM.Standard.A1.Flex"
  }

  # Official Canonical OwnerId for Ubuntu AMIs
  ami_owner = (
    (local.is_gov ?
      "513442679011"
      :
      (local.is_china ?
        "837727238323"
        :
        "099720109477"
      )
    )
  )
  ubuntu_ami = (var.ubuntu_ami != "" ? var.ubuntu_ami : data.aws_ami.ubuntu_20_04_lts[0].id)

  public_key = var.use_existing_keypair ? var.public_key : tls_private_key.ssh_key[0].public_key_openssh

  # Use Resource Group for Azure
  # Use VPC name for GCP (split by project name)
  vpc_id = (
    (local.cloud == "azure" ?
      split(":", var.vpc_id)[1]
      :
      (local.cloud == "gcp" ?
        split("~-~", var.vpc_id)[0]
        :
        var.vpc_id
      )
    )
  )
  # For Azure, grab VNet name from Aviatrix vpc_id
  vnet_name = ""

  zone1 = "${var.region}-${var.az1}"
  zone2 = "${var.region2}-${var.az2}"

  # Use for looping custom subnets list, if vm_count > number of provided subnets
  num_pub_subnet  = length(var.public_subnet_list)
  num_priv_subnet = length(var.private_subnet_list)

  # Use for calculating list of default allowed CIDRs for ingress_cidrs if none provided
  my_ip                 = "${chomp(data.http.my_ip.response_body)}/32"
  vpc_cidr              = data.aws_vpc.vpc[0].cidr_block
  rfc_1918_cidrs        = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  default_ingress_cidrs = concat(local.rfc_1918_cidrs, formatlist(local.my_ip), formatlist(local.vpc_cidr))
  # Always include the VPC CIDR so a public VM acting as a bastion can SSH to
  # private VMs in the same VPC, even when the caller overrides ingress_cidrs.
  # distinct() guards against an exact-duplicate CIDR, which AWS rejects with
  # InvalidPermission.Duplicate in a single SG rule's cidr_blocks list.
  ingress_cidrs = distinct(length(var.ingress_cidrs) > 0 ? concat(var.ingress_cidrs, [local.vpc_cidr]) : local.default_ingress_cidrs)

  # IPv6 ingress CIDRs - default to allow all IPv6 if none provided and IPv6 is enabled
  default_ipv6_ingress_cidrs = var.enable_ipv6 ? ["::/0"] : []
  ipv6_ingress_cidrs         = length(var.ipv6_ingress_cidrs) > 0 ? var.ipv6_ingress_cidrs : local.default_ipv6_ingress_cidrs

  # "Default" tags for the VMs, to merge with additional user-inputted tags
  aws_sg_default_tags = {
    Name  = "${var.resource_name_label}-sg-${var.region}"
    Owner = var.owner
  }
  aws_key_default_tags = {
    Name  = "${var.resource_name_label}-key-${var.region}"
    Owner = var.owner
  }

  aws_sg_tags  = merge(local.aws_sg_default_tags, var.tags)
  aws_key_tags = merge(local.aws_key_default_tags, var.tags)

  # User data
  user_data = var.user_data_filename != "" ? "${file(var.user_data_filename)}" : "${file("${path.module}/../init.sh")}"
}

resource "aws_security_group" "sg" {
  count       = local.cloud == "aws" ? 1 : 0
  name        = "${var.resource_name_label}-sg"
  description = "Allow SSH connection and ICMP to ubuntu instances."
  vpc_id      = local.vpc_id

  ingress {
    # SSH
    from_port   = var.tcp_allow_all_ports ? 0 : 22
    to_port     = var.tcp_allow_all_ports ? 65535 : 22
    protocol    = "tcp"
    cidr_blocks = local.ingress_cidrs
  }
  ingress {
    # ICMP
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = local.ingress_cidrs
  }

  dynamic "ingress" {
    for_each = var.udp_allow_all_ports ? [1] : []
    content {
      from_port   = 0
      to_port     = 65535
      protocol    = "udp"
      cidr_blocks = local.ingress_cidrs
    }
  }

  # IPv6 ingress rules (only if IPv6 is enabled and IPv6 CIDRs are provided)
  dynamic "ingress" {
    for_each = var.enable_ipv6 && length(local.ipv6_ingress_cidrs) > 0 ? [1] : []
    content {
      # SSH
      from_port        = var.tcp_allow_all_ports ? 0 : 22
      to_port          = var.tcp_allow_all_ports ? 65535 : 22
      protocol         = "tcp"
      ipv6_cidr_blocks = local.ipv6_ingress_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.enable_ipv6 && length(local.ipv6_ingress_cidrs) > 0 ? [1] : []
    content {
      # ICMPv6
      from_port        = -1
      to_port          = -1
      protocol         = "icmpv6"
      ipv6_cidr_blocks = local.ipv6_ingress_cidrs
    }
  }

  dynamic "ingress" {
    for_each = var.enable_ipv6 && var.udp_allow_all_ports && length(local.ipv6_ingress_cidrs) > 0 ? [1] : []
    content {
      # UDP
      from_port        = 0
      to_port          = 65535
      protocol         = "udp"
      ipv6_cidr_blocks = local.ipv6_ingress_cidrs
    }
  }

  egress {
    # Allow all
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidrs
  }

  # IPv6 egress rule (only if IPv6 is enabled and IPv6 CIDRs are provided)
  dynamic "egress" {
    for_each = var.enable_ipv6 ? [1] : []
    content {
      # Allow all IPv6
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      ipv6_cidr_blocks = var.ipv6_egress_cidrs
    }
  }

  tags = local.aws_sg_tags
}

/*
    Instance-level scope
*/
resource "random_id" "key_id" {
  count       = local.cloud == "aws" ? 1 : 0
  byte_length = 4
}

resource "aws_key_pair" "key_pair" {
  count      = local.cloud == "aws" ? 1 : 0
  key_name   = "${var.resource_name_label}-key-${random_id.key_id[0].dec}"
  public_key = local.public_key
  tags       = local.aws_key_tags
}

data "aws_ami" "ubuntu_20_04_lts" {
  count       = local.cloud == "aws" ? 1 : 0
  most_recent = true
  owners      = [local.ami_owner] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "public_instance" {
  count                       = local.cloud == "aws" ? var.vm_count : 0
  ami                         = local.ubuntu_ami
  instance_type               = local.instance_size
  disable_api_termination     = var.termination_protection
  associate_public_ip_address = true
  private_ip                  = length(var.public_vm_private_ip_list) > 0 ? var.public_vm_private_ip_list[count.index] : null
  subnet_id                   = var.use_custom_subnets ? var.public_subnet_list[count.index % local.num_pub_subnet] : var.public_subnet_id
  vpc_security_group_ids      = var.use_custom_security_group ? var.vpc_security_group_ids : [aws_security_group.sg[0].id]
  key_name                    = aws_key_pair.key_pair[0].key_name
  ipv6_address_count          = var.enable_ipv6 ? 1 : 0

  # not simplified in locals due to use of count.index
  tags = merge(
    {
      Name  = "${var.resource_name_label}-public-vm${count.index}-${var.region}",
      Owner = var.owner
    },
    var.tags
  )

  user_data = local.user_data

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_instance" "private_instance" {
  count                       = local.cloud == "aws" && var.deploy_private_vm ? var.vm_count : 0
  ami                         = local.ubuntu_ami
  instance_type               = local.instance_size
  disable_api_termination     = var.termination_protection
  associate_public_ip_address = false
  private_ip                  = length(var.private_vm_private_ip_list) > 0 ? var.private_vm_private_ip_list[count.index] : null
  subnet_id                   = var.use_custom_subnets ? var.private_subnet_list[count.index % local.num_priv_subnet] : var.private_subnet_id
  vpc_security_group_ids      = var.use_custom_security_group ? var.vpc_security_group_ids : [aws_security_group.sg[0].id]
  key_name                    = aws_key_pair.key_pair[0].key_name
  ipv6_address_count          = var.enable_ipv6 ? 1 : 0
  source_dest_check           = var.source_dest_check

  # not simplified in locals due to use of count.index
  tags = merge(
    {
      Name  = "${var.resource_name_label}-private-vm${count.index}-${var.region}",
      Owner = var.owner
    },
    var.tags
  )

  user_data = local.user_data

  lifecycle {
    ignore_changes = [ami]
  }
}
