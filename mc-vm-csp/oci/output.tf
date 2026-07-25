output "vm" {
  value = {
    public_vm_obj_list = concat(
      oci_core_instance.public_instance[*]
    )
    private_vm_obj_list = concat(
      oci_core_instance.private_instance[*]
    )
    public_vm_name_list = concat(
      oci_core_instance.public_instance[*].display_name
    )
    private_vm_name_list = concat(
      oci_core_instance.private_instance[*].display_name
    )
    public_vm_id_list = concat(
      oci_core_instance.public_instance[*].id
    )
    private_vm_id_list = concat(
      oci_core_instance.private_instance[*].id
    )
    public_vm_public_ip_list = concat(
      oci_core_instance.public_instance[*].public_ip
    )
    vm_private_ip_list = concat(
      oci_core_instance.public_instance[*].private_ip,
      oci_core_instance.private_instance[*].private_ip
    )
    private_vm_private_ip_list = concat(
      oci_core_instance.private_instance[*].private_ip
    )
    private_key_filename = var.use_existing_keypair ? null : local_file.private_key[0].filename
    nsg_id               = local.cloud == "oci" ? oci_core_network_security_group.nsg[0].id : null
  }
}
