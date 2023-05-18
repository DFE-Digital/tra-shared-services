.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z\.\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: dev
dev: ## set the dev environment variables
	$(eval DEPLOY_ENV=dev)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-development)
	$(eval SERVICE_PRINCIPAL_NAME=s165d01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165d01-rg)
	$(eval RESOURCE_NAME_PREFIX=s165d01)

.PHONY: test
test: ## set the test environment variables
	$(eval DEPLOY_ENV=test)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval SERVICE_PRINCIPAL_NAME=s165t01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165t01-rg)
	$(eval RESOURCE_NAME_PREFIX=s165t01)

.PHONY: pre-production
pre-production: ## set the pre-production environment variables
	$(eval DEPLOY_ENV=preprod)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval SERVICE_PRINCIPAL_NAME=s165t01-preprod-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165t01-preprod-rg)
	$(eval RESOURCE_NAME_PREFIX=s165t01)

.PHONY: production
production: ## set the production environment variables
	$(eval DEPLOY_ENV=production)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-production)
	$(eval SERVICE_PRINCIPAL_NAME=s165p01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165p01-rg)
	$(eval RESOURCE_NAME_PREFIX=s165p01)

apply-for-qts: ## apply to service:  Database of Qualified Teachers
	$(eval DOMAINS_ID=afqts)
	$(eval PRODUCT_NAME=Database of Qualified Teachers)

getanid: ## apply to service:  Get an Identity
	$(eval DOMAINS_ID=getanid)
	$(eval PRODUCT_NAME=Get an Identity)

aytp:  ## apply to service:  Access Your Teaching Profile
	$(eval DOMAINS_ID=aytp)
	$(eval PRODUCT_NAME=Access Your Teaching Profile)

aytq:  ## apply to service:  Access Your Teaching Qualifications
	$(eval DOMAINS_ID=aytq)
	$(eval PRODUCT_NAME=Access Your Teaching Qualifications)

rsm:  ## apply to service:  Refer Serious Misconduct
	$(eval DOMAINS_ID=rsm)
	$(eval PRODUCT_NAME=Refer Serious Misconduct)

trngen:  ## apply to service:  Database of Qualified Teachers
	$(eval DOMAINS_ID=trngen)
	$(eval PRODUCT_NAME=Database of Qualified Teachers)

deploy-azure-resources: set-azure-account set-azure-template-tag set-azure-resource-group-tags   ## make deploy-azure-resources production <apply to service> - setup store for terraform state and keyvault storage, only use w/ production environment, use AUTO_APPROVE=1
	$(if ${AUTO_APPROVE}, , $(error can only run with AUTO_APPROVE)) 
	az deployment sub create --name "resourcedeploy-${DOMAINS_ID}domains-$(shell date +%Y%m%d%H%M%S)" -l "West Europe" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_NAME_PREFIX}-${DOMAINS_ID}domains-rg" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${RESOURCE_NAME_PREFIX}${DOMAINS_ID}domainstf" "tfStorageContainerName=${DOMAINS_ID}domains-tf" \
			"keyVaultName=${RESOURCE_NAME_PREFIX}-${DOMAINS_ID}domains-kv"

set-azure-account:
	az account set -s ${AZURE_SUBSCRIPTION}

set-azure-resource-group-tags: ##Tags that will be added to resource group on it's creation in ARM template
	$(eval RG_TAGS=$(shell echo '{ "Portfolio": "Early Years and Schools Group", "Parent Business":"Teaching Regulation Agency", "Product" : "${PRODUCT_NAME}", "Service Line": "Teaching Workforce", "Service": "Teacher Training and Qualifications", "Service Offering": "${PRODUCT_NAME}", "Environment" : "$(DEPLOY_ENV)"}' | jq . ))

set-azure-template-tag:
	$(eval ARM_TEMPLATE_TAG=1.1.1)

set-production-subscription:
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-production)

domains-infra-init: set-production-subscription set-azure-account ## make  <apply to service>  domains-infra-(terraform workflow)  - setup (init) for main Azure Frontdoor/CDN for that service
	terraform -chdir=custom_domains/infrastructure init -upgrade -reconfigure -backend-config=workspace_variables/${DOMAINS_ID}_backend.tfvars

domains-infra-plan: domains-infra-init ## make  <apply to service>  domains-infra-(terraform workflow)  - setup (plan) for main Azure Frontdoor/CDN for that service
	terraform -chdir=custom_domains/infrastructure plan -var-file workspace_variables/${DOMAINS_ID}.tfvars.json

domains-infra-apply: domains-infra-init ## make  <apply to service>  domains-infra-(terraform workflow)  - setup (apply) for main Azure Frontdoor/CDN for that service
	terraform -chdir=custom_domains/infrastructure apply -var-file workspace_variables/${DOMAINS_ID}.tfvars.json

domains-init: set-production-subscription set-azure-account ## make <env> <apply to service>  domains-(terraform workflow)  - setup (init) Azure Frontdoor/CDN for that service environment
	terraform -chdir=custom_domains/${DOMAINS_ID} init -upgrade -reconfigure -backend-config=workspace_variables/${DOMAINS_ID}_${DEPLOY_ENV}_backend.tfvars

domains-plan: domains-init  ## make <env> <apply to service>  domains-(terraform workflow)  - setup (plan)  Azure Frontdoor/CDN for that service environment
	terraform -chdir=custom_domains/${DOMAINS_ID} plan -var-file workspace_variables/${DOMAINS_ID}_${DEPLOY_ENV}.tfvars.json

domains-state: domains-init  ## make <env> <apply to service>  domains-(terraform workflow)  - setup (show state)  Azure Frontdoor/CDN for that service environment
	terraform -chdir=custom_domains/${DOMAINS_ID} show 

domains-apply: domains-init ## make <env> <apply to service>  donains-(terraform workflow)  - setup (apply) Azure Frontdoor/CDN for that service environment
	terraform -chdir=custom_domains/${DOMAINS_ID} apply -var-file workspace_variables/${DOMAINS_ID}_${DEPLOY_ENV}.tfvars.json

domains-destroy: domains-init ## make <env> <apply to service>  donains-(terraform workflow)  - setup (destroy)  Azure Frontdoor/CDN for that service environment
	terraform -chdir=custom_domains/${DOMAINS_ID} destroy -var-file workspace_variables/${DOMAINS_ID}_${DEPLOY_ENV}.tfvars.json
