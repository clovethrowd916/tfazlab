//Resource Group Values
region_name = {
    primary = "southcentralus"
    failover = "northcentralus"
}

rg_name = {
    networking = "RG-NETWORKING"
    compute = "RG-COMPUTE"
} 

//Networking Values
vnet_address_space = ["20.0.0.0/16"]
subnet_address_space = ["20.0.0.0/24"]
subnet_name = "Infra-02"
vnet_name = "Hub-02"

//Compute Values
dc_server_vm_names = ["dc01"]
server_vm_names = ["aad101", "web01"]
vm_size = "Standard_b2s"

//AD Domain Services Values
active_directory_domain = "htxazlab.com"
active_directory_netbios_name = "LAB"
active_directory_username = "pmanning"
domain_controller_ip = "20.0.0.4"
domain_admin_user = "pmanning@htxazlab.com"

//Key vault values
key_vault_name = "azlab-kv-sc02"
key_vault_rg = "AZ-LAB-HOME-KV"
admin_pw_secret_name = "adminPassword"

