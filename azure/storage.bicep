param storageName string
param storageLocation string
param storageContainers array
param enableVersioning string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageName
  location: storageLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    // immutableStorageWithVersioning: {
    //   enabled: bool(enableVersioning)
    // }

  }
}
resource symbolicname 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
    isVersioningEnabled: bool(enableVersioning)
  }
}

resource storageAccountContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = [for container in storageContainers:  {
  name: '${storageAccount.name}/default/${container}'

}]

// output containers array = cleanedContainersArray
