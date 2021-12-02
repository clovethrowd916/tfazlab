

//Resource Groups
variable "region_name" {
description = "Region selected"    
type = map(any)    
}

variable "rg_name" {
description = "resource group name"
type = map(any)
}


//Networking
variable vnet_address_space  {
description = "Vnet address space"
type = list(any)
} 
variable "subnet_address_space" {
  type = list(any)
}
variable "subnet_name" {}
variable "vnet_name" {}


//Compute
variable "dc_server_vm_names"  {
  type = list(string)
}
variable "server_vm_names" {
  type = list(string)
}
variable "vm_size" {}

//AD Domain Services
variable "domain_controller_ip" {}
variable "active_directory_domain" {}
variable "active_directory_netbios_name" {}
variable "active_directory_username" {}
variable "domain_admin_user" {}
  
 //Key Vault Variables   
variable "key_vault_name" {}
variable "key_vault_rg" {}
variable "admin_pw_secret_name" {}
variable "dns_server_ip" {}