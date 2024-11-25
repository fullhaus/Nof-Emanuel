# Folder with terraform scripts for all environments of platform

## Details

## Using Terraform

### Prerequisites

- Terraform version = v1.8.4
- provider azurerm  = v3.106.0
- provider azuread  = v2.50.0
- provider random   = v3.6.2
- proveider tls     = v4.0.5

### ACR repositories

Used to store services docker images.

List of repositories:
ECS Service name| URL of ACR
--- | ---
TODO | TODO

### Input data
Variable | Description
--- | ---
TODO | TODO


### Output data
Variable | Description
--- | ---
TODO | TODO

### Setup or Usage

* Set AZ(https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with Azure subscription "https://portal.azure.com/#@NETORGFT11301939.onmicrosoft.com/resource/subscriptions/379997e7-730f-4806-ab67-55b2061ac266/overview".
* If you need to change some capacity parameters some environment, please modify file variables.tf or main.tf
* Run `terraform init`.
* Run `terraform workspace new {environmnet}` to create environment(dev,stg,prd).
* Run `terraform workspace select {environmnet}` to switch to appropriate environment(dev,stg,prd).
* Run `terraform plan` to see what changes will terraform try to execute.
* Run `terraform apply` to execute.

### Environments

* Test(test)

## Links
