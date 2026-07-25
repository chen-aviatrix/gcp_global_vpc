module "aviatrix_controlplane" {
  source  = "AviatrixSystems/aws-controlplane/aviatrix"
  version = "~> 1.1"

  # Required
  admin_email       = var.controller_admin_email
  incoming_ssl_cidr = length(var.allowed_cidrs) > 0 ? var.allowed_cidrs : ["0.0.0.0/0"]

  # Region & keypair
  region  = var.aws_region
  keypair = var.key_name

  # Instance sizing
  instance_type         = var.controller_instance_type
  copilot_instance_type = var.copilot_instance_type

  # Licensing
  license_type    = "BYOL"
  avx_customer_id = var.controller_customer_id
  avx_password    = var.controller_admin_password

  # Names
  vpc_name        = "aviatrix-mgmt"
  controller_name = "aviatrix-controller"
  copilot_name    = "aviatrix-copilot"

  # Disable HA and termination protection for a simple single-node deployment
  controller_ha_enabled  = false
  copilot_ha_enabled     = false
  termination_protection = false

  tags = var.tags
}
