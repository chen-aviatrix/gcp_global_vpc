data "alicloud_images" "ubuntu" {
  most_recent = true
  name_regex  = "^ubuntu_20.*64"
}

locals {
  public_key = var.use_existing_keypair ? var.public_key : tls_private_key.ssh_key[0].public_key_openssh

}

resource "alicloud_ecs_key_pair" "key_pair" {
  public_key = local.public_key
}


resource "alicloud_security_group" "group" {
  name        = "tf_test_foo"
  description = "foo"
  vpc_id      = var.vpc_id
}

resource "alicloud_security_group_rule" "ingress" {
  count             = length(var.ingress_cidrs)
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = length(var.ingress_cidrs) > 0 ? var.ingress_cidrs[count.index] : null
}

resource "alicloud_security_group_rule" "egress" {
  count             = length(var.egress_cidrs)
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = length(var.egress_cidrs) > 0 ? var.egress_cidrs[count.index] : null
}


resource "alicloud_instance" "public" {
  image_id                = data.alicloud_images.ubuntu.ids.0
  instance_type           = "ecs.g5ne.large"
  system_disk_category    = "cloud_efficiency"
  system_disk_name        = var.resource_name_label
  system_disk_description = var.resource_name_label

  instance_name              = var.resource_name_label
  internet_max_bandwidth_out = 10
  data_disks {
    name        = "disk2"
    size        = 20
    category    = "cloud_efficiency"
    description = "disk2"
  }
  key_name = alicloud_ecs_key_pair.key_pair.id
  # plain_text_passwd: 'ubuntu'
  user_data       = <<-EOT
#cloud-config
users:
  - default
ssh-keys:
  ubuntu:${local.public_key}
system_info:
  default_user:
    name: ubuntu
    home: /home/ubuntu
    shell: /bin/bash
    gecos: Ubuntu
    lock_passwd: true
    groups: [adm, audio, cdrom, dialout, floppy, video, plugdev, dip, netdev]
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, root
    ssh_authorized_keys:
      - ${local.public_key}
packages:
 - iperf
 - iperf3
 - tcpdump
 - ipset
 - iproute2
EOT
  vswitch_id      = var.public_subnet_id
  security_groups = [alicloud_security_group.group.id]

  tags = merge({
    Name  = "${var.resource_name_label}-sg-${var.region}"
    Owner = var.owner
  }, var.tags)
}

# Alicloud only has public subnets so private vm will not be created