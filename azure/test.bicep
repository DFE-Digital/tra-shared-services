param keyvaultName string
param keyvaultLocation string

resource keyvault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: keyvaultName
  location: keyvaultLocation
  properties: {
    enableRbacAuthorization: true
    enableSoftDelete: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: '9c7d9dd3-840c-4b3f-818e-552865082e16'
  }
}
