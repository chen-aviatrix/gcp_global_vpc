output "controller_public_ip" {
  description = "Public IP of the Aviatrix Controller"
  value       = module.aviatrix_controlplane.controller_public_ip
}

output "copilot_public_ip" {
  description = "Public IP of the Aviatrix CoPilot"
  value       = module.aviatrix_controlplane.copilot_public_ip
}

output "controller_name" {
  value = module.aviatrix_controlplane.controller_name
}

output "copilot_name" {
  value = module.aviatrix_controlplane.copilot_name
}
