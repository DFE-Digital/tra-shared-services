.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z\.\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: dev
dev:
	$(eval DEPLOY_ENV=dev)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-development)
	$(eval SERVICE_PRINCIPAL_NAME=s165d01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165d01-rg)

.PHONY: test
test:
	$(eval DEPLOY_ENV=test)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval SERVICE_PRINCIPAL_NAME=s165t01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165t01-rg)

.PHONY: pre-production
pre-production:
	$(eval DEPLOY_ENV=pre-production)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval SERVICE_PRINCIPAL_NAME=s165t01-preprod-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165t01-preprod-rg)

.PHONY: production
production:
	$(eval DEPLOY_ENV=production)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-production)
	$(eval SERVICE_PRINCIPAL_NAME=s165p01-keyvault-readonly-access)
	$(eval RESOURCE_GROUP_NAME=s165p01-rg)

apply-for-qts:
	$(eval DOMAINS_ID=afqts)

deploy-azure-resources: ## make dev deploy-azure-resources CONFIRM_DEPLOY=1
	$(if $(CONFIRM_DEPLOY), , $(error can only run with CONFIRM_DEPLOY))
	pwsh ./azure/Set-ResourceGroup.ps1 -ResourceGroupName ${RESOURCE_GROUP_NAME} -Subscription ${AZURE_SUBSCRIPTION} -EnvironmentName ${DEPLOY_ENV} -ParametersFile "./azure/azuredeploy.${DEPLOY_ENV}.parameters.json" -ServicePrincipalName ${SERVICE_PRINCIPAL_NAME}

domains-base-init:
	terraform -chdir=custom_domains/base init -upgrade -reconfigure -backend-config=workspace_variables/${DOMAINS_ID}_backend.tfvars

domains-base-plan: domains-base-init
	terraform -chdir=custom_domains/base plan -var-file workspace_variables/${DOMAINS_ID}.tfvars.json

domains-base-apply: domains-base-init
	terraform -chdir=custom_domains/base apply -var-file workspace_variables/${DOMAINS_ID}.tfvars.json
