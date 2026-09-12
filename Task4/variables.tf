variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.0.0/24"
}

variable "admin_cidrs" {
  description = "Адреса, с которых разрешён SSH на bastion"
  type        = list(string)
}

variable "ssh_public_key_path" {
  type = string
}

variable "bastion" {
  type = object({
    cores     = number
    memory    = number
    disk_size = number
  })
}

variable "platform_vms" {
  description = "VM платформы данных: имя -> vCPU, RAM в ГБ, загрузочный диск в ГБ"
  type = map(object({
    cores     = number
    memory    = number
    disk_size = number
  }))
}

variable "lakehouse_bucket" {
  type = string
}
