output "vm" {
  value = {
    public_ip  = alicloud_instance.public.public_ip
    private_ip = alicloud_instance.public.private_ip
  }
}
