variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name for SSH access to controller and copilot"
}

variable "controller_instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "copilot_instance_type" {
  type    = string
  default = "t3.2xlarge"
}

variable "controller_admin_email" {
  type        = string
  description = "Email address for the Aviatrix controller admin account"
}

variable "controller_admin_password" {
  type        = string
  sensitive   = true
  description = "Initial admin password for the Aviatrix controller"
}

variable "controller_customer_id" {
  type        = string
  sensitive   = true
  description = "Aviatrix customer ID / license key (BYOL)"
}

variable "allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "Source CIDRs allowed to reach HTTPS on the controller and copilot."
}

variable "tags" {
  type    = map(string)
  default = {}
}
