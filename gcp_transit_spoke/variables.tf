variable "controller_ip" {
  type    = string
  default = "35.83.233.153"
}

variable "controller_password" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "aviatrix_aws_account" {
  type        = string
  description = "Aviatrix access account name for AWS (as registered in the controller)"
  default     = "aws_admin"
}

variable "aviatrix_gcp_account" {
  type        = string
  description = "Aviatrix access account name for GCP (as registered in the controller)"
  default     = "gcp_admin"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID to onboard"
  default     = "edumanig-01-368302"
}

variable "gcp_credentials_file" {
  type        = string
  description = "Path to the GCP service account JSON key file"
  default     = "/Users/cliu@aviatrix.com/aviatrix-gcp-key.json"
}

variable "pre_shared_key" {
  default = "avx"
}

variable "ingress_cidrs" {
  type        = list(string)
  description = "CIDRs allowed for SSH/ICMP ingress to test VMs. Override per cloudn convention via provider_cred.tfvars."
  default     = ["0.0.0.0/0"]
}

# Retrieve local public IP
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}
