data "oci_core_vcn" "vcn" {
  count  = local.cloud == "oci" ? 1 : 0
  vcn_id = local.vpc_id
}

data "oci_core_subnet" "public_input_subnet" {
  count     = local.cloud == "oci" ? 1 : 0
  subnet_id = var.use_custom_subnets ? var.public_subnet_list[count.index] : var.public_subnet_id
}

data "oci_core_subnet" "private_input_subnet" {
  count     = local.cloud == "oci" ? 1 : 0
  subnet_id = var.use_custom_subnets ? var.private_subnet_list[count.index] : var.private_subnet_id
}

data "oci_identity_availability_domains" "ad" {
  count          = local.cloud == "oci" ? 1 : 0
  compartment_id = data.oci_core_subnet.public_input_subnet[0].compartment_id
}

/*
    Local vars
*/
locals {
  cloud = "oci"

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
  ubuntu_ami = var.ubuntu_ami

  public_key = var.use_existing_keypair ? var.public_key : tls_private_key.ssh_key[0].public_key_openssh

  # Use Resource Group for Azure
  # Use VPC name for GCP (split by project name)
  vpc_id = var.vpc_id
  # For Azure, grab VNet name from Aviatrix vpc_id
  vnet_name = local.cloud == "azure" ? split(":", var.vpc_id)[0] : ""

  zone1 = "${var.region}-${var.az1}"
  zone2 = "${var.region2}-${var.az2}"

  # Use for looping custom subnets list, if vm_count > number of provided subnets
  num_pub_subnet  = length(var.public_subnet_list)
  num_priv_subnet = length(var.private_subnet_list)

  # Use for calculating list of default allowed CIDRs for ingress_cidrs if none provided
  my_ip                 = "${chomp(data.http.my_ip.response_body)}/32"
  vpc_cidr              = data.oci_core_vcn.vcn[0].cidr_blocks[0]
  rfc_1918_cidrs        = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  default_ingress_cidrs = concat(local.rfc_1918_cidrs, formatlist(local.my_ip), formatlist(local.vpc_cidr))
  # Always include the VPC CIDR so a public VM acting as a bastion can SSH to
  # private VMs in the same VPC, even when the caller overrides ingress_cidrs.
  ingress_cidrs = length(var.ingress_cidrs) > 0 ? concat(var.ingress_cidrs, [local.vpc_cidr]) : local.default_ingress_cidrs

  # User data
  user_data = var.user_data_filename != "" ? "${file(var.user_data_filename)}" : "${file("${path.module}/../init.sh")}"
}

/*
    Networking-level scope
*/
resource "oci_core_network_security_group" "nsg" {
  count          = local.cloud == "oci" ? 1 : 0
  compartment_id = data.oci_core_subnet.public_input_subnet[0].compartment_id
  vcn_id         = local.vpc_id
}

resource "oci_core_network_security_group_security_rule" "egress" {
  count                     = local.cloud == "oci" ? length(var.egress_cidrs) : 0
  network_security_group_id = oci_core_network_security_group.nsg[0].id

  direction   = "EGRESS"
  protocol    = "all"
  destination = var.egress_cidrs[count.index]
}

resource "oci_core_network_security_group_security_rule" "ingress_ssh" {
  # Only create if OCI. If var.ingress_cidrs are specified, num of rules == num of elements, otherwise create 5
  # hard-coded 5 value due to TF not handling calculated argument of num of local.ingress_cidrs
  # +1 for the VPC CIDR appended to local.ingress_cidrs when var.ingress_cidrs is set
  count                     = (local.cloud == "oci" ? (length(var.ingress_cidrs) > 0 ? length(var.ingress_cidrs) + 1 : 5) : 0)
  network_security_group_id = oci_core_network_security_group.nsg[0].id

  direction = "INGRESS"
  protocol  = 6 # TCP
  source    = local.ingress_cidrs[count.index]
  stateless = false

  tcp_options {
    destination_port_range {
      min = var.tcp_allow_all_ports ? 0 : 22
      max = var.tcp_allow_all_ports ? 65535 : 22
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_udp" {
  # Only create if OCI and udp_allow_all_ports is true
  # +1 for the VPC CIDR appended to local.ingress_cidrs when var.ingress_cidrs is set
  count                     = (local.cloud == "oci" && var.udp_allow_all_ports ? (length(var.ingress_cidrs) > 0 ? length(var.ingress_cidrs) + 1 : 5) : 0)
  network_security_group_id = oci_core_network_security_group.nsg[0].id

  direction = "INGRESS"
  protocol  = 17 # UDP
  source    = local.ingress_cidrs[count.index]
  stateless = false

  udp_options {
    destination_port_range {
      min = 0
      max = 65535
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_icmp" {
  # Only create if OCI. If var.ingress_cidrs are specified, num of rules == num of elements, otherwise create 5
  # hard-coded 5 value due to TF not handling calculated argument of num of local.ingress_cidrs
  # +1 for the VPC CIDR appended to local.ingress_cidrs when var.ingress_cidrs is set
  count                     = (local.cloud == "oci" ? (length(var.ingress_cidrs) > 0 ? length(var.ingress_cidrs) + 1 : 5) : 0)
  network_security_group_id = oci_core_network_security_group.nsg[0].id

  direction = "INGRESS"
  protocol  = 1 # ICMP
  source    = local.ingress_cidrs[count.index]
  stateless = false
}

/*
    Instance-level scope
*/
data "oci_core_images" "ubuntu_image" {
  count                    = local.cloud == "oci" ? 1 : 0
  compartment_id           = data.oci_core_subnet.public_input_subnet[0].compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "20.04"
}

resource "oci_core_instance" "public_instance" {
  count               = local.cloud == "oci" ? var.vm_count : 0
  availability_domain = data.oci_identity_availability_domains.ad[0].availability_domains[0].name
  compartment_id      = data.oci_core_subnet.public_input_subnet[0].compartment_id
  shape               = local.instance_size

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_image[0].images[0].id
  }

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  create_vnic_details {
    assign_public_ip = true
    private_ip       = length(var.public_vm_private_ip_list) > 0 ? var.public_vm_private_ip_list[count.index] : null
    subnet_id        = var.use_custom_subnets ? var.public_subnet_list[count.index % local.num_pub_subnet] : var.public_subnet_id
    display_name     = "${var.resource_name_label}-ubuntu-public-nic${count.index}"
    hostname_label   = "${var.resource_name_label}-ubuntu${count.index}"
    nsg_ids          = [oci_core_network_security_group.nsg[0].id]
  }

  metadata = {
    ssh_authorized_keys = local.public_key,
    user_data           = base64encode(local.user_data)
  }

  display_name = "${var.resource_name_label}-public-vm${count.index}"
  # not simplified in locals due to use of count.index
  freeform_tags = merge(
    {
      Name  = "${var.resource_name_label}-public-vm${count.index}-${var.region}",
      Owner = var.owner
    },
    var.tags
  )
}

resource "oci_core_instance" "private_instance" {
  count               = local.cloud == "oci" ? var.vm_count : 0
  availability_domain = data.oci_identity_availability_domains.ad[0].availability_domains[0].name
  compartment_id      = data.oci_core_subnet.private_input_subnet[0].compartment_id
  shape               = local.instance_size

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_image[0].images[0].id
  }

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  create_vnic_details {
    assign_public_ip = false
    private_ip       = length(var.private_vm_private_ip_list) > 0 ? var.private_vm_private_ip_list[count.index] : null
    subnet_id        = var.use_custom_subnets ? var.private_subnet_list[count.index % local.num_priv_subnet] : var.private_subnet_id
    display_name     = "${var.resource_name_label}-ubuntu-private-nic${count.index}"
    hostname_label   = "${var.resource_name_label}-ubuntu${count.index}"
    nsg_ids          = [oci_core_network_security_group.nsg[0].id]
  }

  metadata = {
    ssh_authorized_keys = local.public_key,
    user_data           = base64encode(local.user_data)
  }

  display_name = "${var.resource_name_label}-private-vm${count.index}"
  # not simplified in locals due to use of count.index
  freeform_tags = merge(
    {
      Name  = "${var.resource_name_label}-private-vm${count.index}-${var.region}",
      Owner = var.owner
    },
    var.tags
  )
}
