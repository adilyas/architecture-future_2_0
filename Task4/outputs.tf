output "network_id" {
  value = yandex_vpc_network.platform.id
}

output "subnet_id" {
  value = yandex_vpc_subnet.platform.id
}

output "nat_gateway_id" {
  value = yandex_vpc_gateway.nat.id
}

output "bastion_public_ip" {
  value = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "platform_vm_ips" {
  value = { for name, vm in yandex_compute_instance.platform : name => vm.network_interface[0].ip_address }
}

output "lakehouse_bucket" {
  value = yandex_storage_bucket.lakehouse.bucket
}
