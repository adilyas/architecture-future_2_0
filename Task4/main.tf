terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# Сеть среды платформы данных

resource "yandex_vpc_network" "platform" {
  name = "platform-network"
}

resource "yandex_vpc_gateway" "nat" {
  name = "platform-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat" {
  name       = "platform-nat-route"
  network_id = yandex_vpc_network.platform.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "platform" {
  name           = "platform-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.platform.id
  v4_cidr_blocks = [var.subnet_cidr]
  route_table_id = yandex_vpc_route_table.nat.id
}

resource "yandex_vpc_security_group" "bastion" {
  name       = "platform-bastion"
  network_id = yandex_vpc_network.platform.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = var.admin_cidrs
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "platform" {
  name       = "platform-internal"
  network_id = yandex_vpc_network.platform.id

  ingress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = [var.subnet_cidr]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Bastion: единственная VM с публичным адресом, через неё инженеры ходят по SSH к остальным

resource "yandex_compute_disk" "bastion" {
  name     = "platform-bastion-disk"
  type     = "network-ssd"
  zone     = var.zone
  image_id = data.yandex_compute_image.ubuntu.image_id
  size     = var.bastion.disk_size
}

resource "yandex_compute_instance" "bastion" {
  name        = "platform-bastion"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = var.bastion.cores
    memory = var.bastion.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.bastion.id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.platform.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# VM платформы: Airflow, Dremio, Nessie, DataHub, Keycloak. Без публичных адресов, в интернет через NAT-шлюз

resource "yandex_compute_disk" "platform" {
  for_each = var.platform_vms

  name     = "platform-${each.key}-disk"
  type     = "network-ssd"
  zone     = var.zone
  image_id = data.yandex_compute_image.ubuntu.image_id
  size     = each.value.disk_size
}

resource "yandex_compute_instance" "platform" {
  for_each = var.platform_vms

  name        = "platform-${each.key}"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.platform[each.key].id
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.platform.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.platform.id]
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key_path)}"
  }
}

# Object Storage под Lakehouse

resource "yandex_storage_bucket" "lakehouse" {
  bucket    = var.lakehouse_bucket
  folder_id = var.folder_id
}
