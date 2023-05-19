# tra-shared-services

A repository of programs to create basic services/resources using make and terraform

- Azure Frontdoor/CDN

## requirementa

- make
- az cli
- terraform
- tfenv [optional]


! may of these command require you to login first (az login)

## Basic 'make' usage'

$ make # basic usage instructions

$ make  (service) deploy-azure-resources # creates terraform state storage and keyvault for that service.

$ make (service) domains-infra-(terraform-workflow) # create main frontdoor/cdn resources for that service using terraform workflow

$ make (environment) (service) domain-(workflow) # create service domain frontdoor/cdn for that service using terraform workflow


# Frontdoor/CDN setup

For each service, a /custom_domains/infrastructure/workspace_variables  folder is needed, two files for each service:

- (service)_backend.tvars   for terraform state storage
- (service)_tfvars.json     for frontdoor settings


for each service enviroment, set in /custom_domains/(service)/workspace_variables/

- (service)_(env)_backend.tfvars  for terraform state storage
- (service)_(env)_tfvars.json     for environment frontdoor settings




