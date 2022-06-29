targetScope='subscription'

param environmentName string

@allowed([
  'find'
  'dqtapi'
  'applyqts'
])
param serviceName string
param resourceGroupLocation string
param enableStorageVersioning string
param storageContainers string

var containersArray = split(storageContainers, ',')
var commonTags  = {
  'Parent Business': 'Teacher Training and Qualifications'
  'Portfolio': 'Early Years and Schools Group'
  'Service': 'Teacher Training and Qualifications'
  'Service Line': 'Teaching Workforce'
  'Environment': environmentName
}

var environmentSettings = {
  dev: {
    subPrefix: 'd01'
    envCode: 'dv'
  }
  test: {
    subPrefix: 't01'
    envCode: 'ts'
  }
  preprod: {
    subPrefix: 't01'
    envCode: 'pp'
  }
  production: {
    subPrefix: 'p01'
    envCode: 'pr'
  }
}

var serviceSettings = {
  find: {
    serviceTags: {
      'Product': 'Find a Lost TRN'
      'Service Offering': 'Find a Lost TRN'
    }

  }
  dqtapi: {
    serviceTags: {
      'Product': 'Database of Qualified Teachers'
      'Service Offering': 'Database of Qualified Teachers'
    }
  }
  applyqts: {
    serviceTags: {
      'Product': 'Apply for QTS'
      'Service Offering': 'Apply for QTS'
    }
  }
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 's165${environmentSettings[environmentName].subPrefix}-${serviceName}-${environmentSettings[environmentName].envCode}-rg'
  location: resourceGroupLocation
  tags: union(commonTags, serviceSettings[serviceName].serviceTags)
}



module storageModule 'storage.bicep' = {
  name: 'storageModule'
  scope: resourceGroup
  params: {
    storageName: 's165${environmentSettings[environmentName].subPrefix}${serviceName}tfstate${environmentSettings[environmentName].envCode}'
    storageLocation: resourceGroupLocation
    enableVersioning: enableStorageVersioning
    storageContainers: containersArray
  }
}

module keyvaultModule 'keyvault.bicep' = {
  name: 'keyvaultModule'
  scope: resourceGroup
  params: {
    keyvaultName: 's165${environmentSettings[environmentName].subPrefix}-${serviceName}-${environmentSettings[environmentName].envCode}-kv'
    keyvaultLocation: resourceGroupLocation
  }
}

output cleanedContiner string = storageContainers
