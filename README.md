# tfazlab
Terraform script to deploy a basic lab
Script deploys domain controller/member servers in Azure and joins member servers to domain.

Variable values are set in the tfvars file. 

Key Vault & secret need to be created beforehand.

Unique values: Key Vault, Key Vault RG, admin_pw_secret_name, active_directory_domain
