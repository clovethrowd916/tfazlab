# tfazlab
Terraform script to deploy a basic lab
Script to deploy domain controller, member servers to Azure

The process of creating Active Directory domain and Joining vms to domain is completely automated.
Servers included in "server_vm_names" list will automatically be joined to domain upon script execution.

Variable values are set in the tfvars file. 

