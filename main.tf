
//Set Providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
    random = {
      source = "hashicorp/random"
      version = "2.3.0"
    }
  }
}

provider "azurerm" {
  
  features {}

}

// Bring in Key Vault
data "azurerm_key_vault" "kv" {
  name = "azlab-kv-sc02"
  resource_group_name = "AZ-LAB-HOME-KV"
}
data "azurerm_key_vault_secret" "kv-secret" {
  name                = var.admin_pw_secret_name
  key_vault_id        = data.azurerm_key_vault.kv.id
}

//Generate Random String for Public IP DNS Label suffix
resource "random_string" "random" {
  length = 5
  special = false
  upper = false
}

output "random_name" {
  value = random_string.random.result
}

//Create Resource Groups
resource "azurerm_resource_group" "rg-network" {

name        = var.rg_name["networking"]
location    = var.region_name["primary"]
}

resource "azurerm_resource_group" "rg-compute" {

name        = var.rg_name["compute"]
location    = var.region_name["primary"]
}

resource "azurerm_virtual_network" "main_vnet" {
  address_space = var.vnet_address_space
  location = var.region_name["primary"]
  name =  var.vnet_name
  resource_group_name = azurerm_resource_group.rg-network
  dns_servers = var.domain_controller_ip
}

resource "azurerm_subnet" "infra_subnet" {
  name = var.subnet_name
  resource_group_name = azurerm_resource_group.rg-network
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes = var.subnet_address_space
}


//Create VNET & Subnet
/* module "network" {
  source = "Azure/network/azurerm"
  
  vnet_name               = "Hub-02"
  resource_group_name     = azurerm_resource_group.rg-network.name
  address_spaces          = ["20.0.0.0/16"]
  subnet_prefixes         = ["20.0.0.0/24"]
  subnet_names            = ["Infra-02"]
  dns_servers             = ["20.0.0.4"]


depends_on = [
  azurerm_resource_group.rg-network
]

} */

// Create Public Ip Address-DC Servers
resource "azurerm_public_ip" "dc_pub_ip" {
  count               = length(var.dc_server_vm_names)
  name                = "${var.dc_server_vm_names[count.index]}-PIP"
  location            = azurerm_resource_group.rg-network.location
  resource_group_name = azurerm_resource_group.rg-network.name
  allocation_method   = "Static"
  domain_name_label   = "${var.dc_server_vm_names[count.index]}-${random_string.random.result}"
}

// Create Public Ip Address-Member Servers
resource "azurerm_public_ip" "server_pub_ip" {
  count               = length(var.server_vm_names)
  name                = "${var.server_vm_names[count.index]}-PIP"
  location            = azurerm_resource_group.rg-network.location
  resource_group_name = azurerm_resource_group.rg-network.name
  allocation_method   = "Static"
  domain_name_label   = "${var.server_vm_names[count.index]}-${random_string.random.result}"
}

//Create DC  NICs
resource "azurerm_network_interface" "dc_server_vm_nic" {
  count               = length(var.dc_server_vm_names)
  name                = "${var.dc_server_vm_names[count.index]}-NIC"
  location            = azurerm_resource_group.rg-network.location
  resource_group_name = azurerm_resource_group.rg-network.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.infra_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.domain_controller_ip
    public_ip_address_id          = element(azurerm_public_ip.dc_pub_ip.*.id, count.index)
    
  }
}

//Create Member Server  NICs
resource "azurerm_network_interface" "member_server_vm_nic" {
  count               = length(var.server_vm_names)
  name                = "${var.server_vm_names[count.index]}-NIC"
  location            = azurerm_resource_group.rg-network.location
  resource_group_name = azurerm_resource_group.rg-network.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.infra_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = element(azurerm_public_ip.server_pub_ip.*.id, count.index)
    
  }
  depends_on = [
    azurerm_network_interface.dc_server_vm_nic
  ]

}

//Create DC VMs
resource "azurerm_windows_virtual_machine" "dc_vm" {
  count = length(var.dc_server_vm_names)
  name                = element(var.dc_server_vm_names,count.index)
  resource_group_name = azurerm_resource_group.rg-compute.name
  location            = azurerm_resource_group.rg-compute.location
  size                = var.vm_size
  admin_username      = var.active_directory_username
  admin_password      = data.azurerm_key_vault_secret.kv-secret.value
  network_interface_ids = [
    element(azurerm_network_interface.dc_server_vm_nic.*.id, count.index)
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

}

//Create Member Server VMs
resource "azurerm_windows_virtual_machine" "member_vm" {
  count = length(var.server_vm_names)
  name                = element(var.server_vm_names,count.index)
  resource_group_name = azurerm_resource_group.rg-compute.name
  location            = azurerm_resource_group.rg-compute.location
  size                = var.vm_size
  admin_username      = var.active_directory_username
  admin_password      = data.azurerm_key_vault_secret.kv-secret.value
  network_interface_ids = [
    element(azurerm_network_interface.member_server_vm_nic.*.id, count.index)
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

}

//set local commands
// the `exit_code_hack` is to keep the VM Extension resource happy

locals {
  import_command       = "Import-Module -Name ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${data.azurerm_key_vault_secret.kv-secret.value} -AsPlainText -Force"
  install_ad_command   = "Add-WindowsFeature -Name ad-domain-services -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode WinThreshold -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode WinThreshold -InstallDns:$true -NoRebootOnCompletion:$false -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 10"
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}


//Promote DC01
resource "azurerm_virtual_machine_extension" "create-active-directory-forest" {
  count = length(var.dc_server_vm_names)
  name                 = "create-active-directory-forest"
  virtual_machine_id   =  element(azurerm_windows_virtual_machine.dc_vm.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}


resource "azurerm_virtual_machine_extension" "join-domain" {
  count = length(var.server_vm_names)
  name                 = "join-vm-to-domain"
  virtual_machine_id   =  element(azurerm_windows_virtual_machine.member_vm.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

   settings = <<SETTINGS
    {
        "Name": "${var.active_directory_domain}",
        "OUPath": "",
        "User": "${var.domain_admin_user}",
        "Restart": "true",
        "Options": "3"
    }
SETTINGS

  protected_settings = <<SETTINGS
    {
        "Password": "${data.azurerm_key_vault_secret.kv-secret.value}"
    }
SETTINGS

depends_on = [
  azurerm_virtual_machine_extension.create-active-directory-forest
]

}

