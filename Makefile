.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash
ENABLE_STORAGE_VERSIONING = true

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

deploy-azure-resources: ## make dev deploy-azure-resources CONFIRM_DEPLOY=1
	$(if $(CONFIRM_DEPLOY), , $(error can only run with CONFIRM_DEPLOY))
	pwsh ./azure/Set-ResourceGroup.ps1 -ResourceGroupName ${RESOURCE_GROUP_NAME} -Subscription ${AZURE_SUBSCRIPTION} -EnvironmentName ${DEPLOY_ENV} -ParametersFile "./azure/azuredeploy.${DEPLOY_ENV}.parameters.json" -ServicePrincipalName ${SERVICE_PRINCIPAL_NAME}

deploy-azure-resources-bicep: ## make dev deploy-azure-resources CONFIRM_DEPLOY=1
	$(if $(SERVICE_NAME), , $(error SERVICE_NAME is required))
	$(if $(STORAGE_CONTAINERS), , $(error STORAGE_CONTAINERS is required. A string with ',' delimiter. example(STORAGE_CONTAINERS="container1,continer2,container3")))

	[[ "${DRY_RUN}" = "true" ]]
	az deployment sub create --template-file ./azure/azure.bicep --parameters serviceName=${SERVICE_NAME} resourceGroupLocation='WestEurope' environmentName=${DEPLOY_ENV} enableStorageVersioning=${ENABLE_STORAGE_VERSIONING} storageContainers=${STORAGE_CONTAINERS} --location WestEurope --what-if
	[[ "${CONFIRM_DEPLOY}" = "YES" ]]
	az deployment sub create --template-file ./azure/azure.bicep --parameters serviceName=${SERVICE_NAME} resourceGroupLocation='WestEurope' environmentName=${DEPLOY_ENV} enableStorageVersioning=${ENABLE_STORAGE_VERSIONING} storageContainers=${STORAGE_CONTAINERS} --location WestEurope
