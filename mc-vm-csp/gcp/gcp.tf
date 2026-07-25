resource "google_compute_firewall" "ingress_firewall" {
  count         = local.cloud == "gcp" ? 1 : 0
  name          = "${var.resource_name_label}-ingress-firewall"
  network       = local.vpc_id
  source_ranges = local.ingress_cidrs

  allow {
    protocol = "icmp"
  }

  allow {
    #SSH
    protocol = "tcp"
    ports    = var.tcp_allow_all_ports ? ["0-65535"] : ["22"]
  }

  dynamic "allow" {
    for_each = var.udp_allow_all_ports ? [1] : [] # Only create UDP rule if udp_allow_all_ports is true
    content {
      protocol = "udp"
      ports    = ["0-65535"]
    }
  }

  target_tags = ["${var.resource_name_label}-ingress-fw"]
}

# IPv6 ingress firewall — split from IPv4 because GCP requires separate
# rules per IP family (and uses protocol number "58" for ICMPv6 in place of
# "icmp")
resource "google_compute_firewall" "ipv6_ingress_firewall" {
  count         = local.cloud == "gcp" && var.enable_ipv6 ? 1 : 0
  name          = "${var.resource_name_label}-ipv6-ingress-firewall"
  network       = local.vpc_id
  source_ranges = local.ipv6_ingress_cidrs

  # ICMPv6 (used by ping6 / connectivity tests)
  allow {
    protocol = "58"
  }

  allow {
    # SSH over IPv6
    protocol = "tcp"
    ports    = var.tcp_allow_all_ports ? ["0-65535"] : ["22"]
  }

  dynamic "allow" {
    for_each = var.udp_allow_all_ports ? [1] : []
    content {
      protocol = "udp"
      ports    = ["0-65535"]
    }
  }

  target_tags = ["${var.resource_name_label}-ingress-fw"]
}

// local vars
locals {
  cloud = "gcp"

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
  vpc_id = split("~-~", var.vpc_id)[0]
  # For Azure, grab VNet name from Aviatrix vpc_id
  vnet_name = ""

  zone1 = "${var.region}-${var.az1}"
  zone2 = "${var.region2}-${var.az2}"

  # Use for looping custom subnets list, if vm_count > number of provided subnets
  num_pub_subnet  = length(var.public_subnet_list)
  num_priv_subnet = length(var.private_subnet_list)

  # Use for calculating list of default allowed CIDRs for ingress_cidrs if none provided
  my_ip                 = "${chomp(data.http.my_ip.response_body)}/32"
  vpc_cidr              = ""
  rfc_1918_cidrs        = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  default_ingress_cidrs = concat(local.rfc_1918_cidrs, formatlist(local.my_ip), formatlist(local.vpc_cidr))
  ingress_cidrs         = length(var.ingress_cidrs) > 0 ? var.ingress_cidrs : local.default_ingress_cidrs

  # IPv6 ingress CIDRs - default to allow-all IPv6 if none provided and IPv6 is enabled
  default_ipv6_ingress_cidrs = var.enable_ipv6 ? ["::/0"] : []
  ipv6_ingress_cidrs         = length(var.ipv6_ingress_cidrs) > 0 ? var.ipv6_ingress_cidrs : local.default_ipv6_ingress_cidrs

  # User data
  user_data = var.user_data_filename != "" ? "${file(var.user_data_filename)}" : "${file("${path.module}/../init.sh")}"
}

resource "google_compute_firewall" "egress_firewall" {
  count         = local.cloud == "gcp" ? 1 : 0
  name          = "${var.resource_name_label}-egress-firewall"
  network       = local.vpc_id
  direction     = "EGRESS"
  source_ranges = var.egress_cidrs

  allow {
    protocol = "all"
  }

  target_tags = ["${var.resource_name_label}-egress-fw"]
}

# IPv6 egress firewall — only created when IPv6 is enabled
resource "google_compute_firewall" "ipv6_egress_firewall" {
  count         = local.cloud == "gcp" && var.enable_ipv6 ? 1 : 0
  name          = "${var.resource_name_label}-ipv6-egress-firewall"
  network       = local.vpc_id
  direction     = "EGRESS"
  source_ranges = var.ipv6_egress_cidrs

  allow {
    protocol = "all"
  }

  target_tags = ["${var.resource_name_label}-egress-fw"]
}

resource "google_compute_instance" "public_instance" {
  count        = local.cloud == "gcp" ? var.vm_count : 0
  name         = "${var.resource_name_label}-public-vm${count.index}"
  machine_type = local.instance_size
  zone         = var.use_custom_subnets ? "${var.public_subnet_region_list[count.index % local.num_pub_subnet]}-${var.az1}" : local.zone1

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = local.vpc_id
    subnetwork = var.use_custom_subnets ? var.public_subnet_list[count.index % local.num_pub_subnet] : var.public_subnet_id
    network_ip = length(var.public_vm_private_ip_list) > 0 ? var.public_vm_private_ip_list[count.index] : null
    stack_type = var.enable_ipv6 ? "IPV4_IPV6" : "IPV4_ONLY"

    # assign external ephemeral IPv4 address
    access_config {}

    # assign external ephemeral IPv6 address only when IPv6 is enabled AND
    # the caller asks for external access (subnet ipv6_access_type = EXTERNAL).
    dynamic "ipv6_access_config" {
      for_each = var.enable_ipv6 && var.assign_external_ipv6 ? [1] : []
      content {
        network_tier = "PREMIUM"
      }
    }
  }

  metadata = {
    ssh-keys  = "${var.vm_admin_username}:${local.public_key}",
    user-data = local.user_data
  }

  # not simplified in locals due to use of count.index
  # GCP keys must be lowercase, numbers, underscores and dashes. 63 char max
  labels = merge(
    {
      name  = "${var.resource_name_label}-public-vm${count.index}-${var.region}",
      owner = var.owner
    },
    var.tags
  )

  tags = ["${var.resource_name_label}-ingress-fw", "${var.resource_name_label}-egress-fw"]


  lifecycle {
    ignore_changes = [tags]
  }
}

resource "google_compute_instance" "private_instance" {
  count        = local.cloud == "gcp" ? var.vm_count : 0
  name         = "${var.resource_name_label}-private-vm${count.index}"
  machine_type = local.instance_size
  zone         = var.use_custom_subnets ? "${var.private_subnet_region_list[count.index % local.num_priv_subnet]}-${var.az2}" : local.zone2

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
    }
  }

  network_interface {
    network    = local.vpc_id
    subnetwork = var.use_custom_subnets ? var.private_subnet_list[count.index % local.num_priv_subnet] : var.private_subnet_id
    network_ip = length(var.private_vm_private_ip_list) > 0 ? var.private_vm_private_ip_list[count.index] : null
    stack_type = var.enable_ipv6 ? "IPV4_IPV6" : "IPV4_ONLY"
    # private VMs get an internal IPv6 address (no external IPv6 access_config)
  }

  metadata = {
    ssh-keys  = "${var.vm_admin_username}:${local.public_key}",
    user-data = local.user_data
  }

  # not simplified in locals due to use of count.index
  # GCP keys must be lowercase, numbers, underscores and dashes. 63 char max
  labels = merge(
    {
      name  = "${var.resource_name_label}-private-vm${count.index}-${var.region}",
      owner = var.owner
    },
    var.tags
  )

  tags = [
    "${var.resource_name_label}-ingress-fw",
    "${var.resource_name_label}-egress-fw",
    var.gcp_egress_private_vm ? "avx-snat-noip" : "dummy"
  ]
  lifecycle {
    ignore_changes = [tags]
  }
}
