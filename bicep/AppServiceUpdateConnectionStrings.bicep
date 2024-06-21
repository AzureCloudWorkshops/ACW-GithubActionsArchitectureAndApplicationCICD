param webAppName string 
param defaultDBSecretURI string
param managerDBSecretURI string
param identityDBConnectionStringKey string
param managerDBConnectionStringKey string 

var kvSecretUriIdentity = '@Microsoft.KeyVault(SecretUri=${defaultDBSecretURI})'
var kvSecretUriManager = '@Microsoft.KeyVault(SecretUri=${managerDBSecretURI})'

resource webApp 'Microsoft.Web/sites@2023-01-01' existing = {
  name: webAppName
}

resource connectionStrings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: webApp
  properties: {
    '${identityDBConnectionStringKey}': { value: kvSecretUriIdentity, type: 'SQLAzure' }
    '${managerDBConnectionStringKey}': { value: kvSecretUriManager, type: 'SQLAzure' }
  } 
}
