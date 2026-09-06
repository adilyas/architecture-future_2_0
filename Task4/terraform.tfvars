cloud_id  = "b1gj8ffntrim9e9s5nja"
folder_id = "b1g8pfqnv12skeoh29dj"
zone      = "ru-central1-a"

subnet_cidr = "10.10.0.0/24"
admin_cidrs = ["0.0.0.0/0"]

ssh_public_key_path = "~/.ssh/yandex_vm.pub"

bastion = {
  cores     = 2
  memory    = 2
  disk_size = 10
}

platform_vms = {
  airflow = {
    cores     = 2
    memory    = 4
    disk_size = 30
  }
  dremio = {
    cores     = 4
    memory    = 16
    disk_size = 50
  }
  nessie = {
    cores     = 2
    memory    = 2
    disk_size = 15
  }
  datahub = {
    cores     = 4
    memory    = 8
    disk_size = 40
  }
  keycloak = {
    cores     = 2
    memory    = 4
    disk_size = 20
  }
}

lakehouse_bucket = "future20-platform-lakehouse"
