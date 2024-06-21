param location string
@description('Provide a unique datetime and initials string to make your instances unique. Use only lower case letters and numbers')
@minLength(11)
@maxLength(11)
param uniqueIdentifier string

@minLength(10)
@maxLength(13)
param keyVaultName string
param keyVaultAdminGroupObjectId string = ''
param enableKeyVaultForDeployments bool = true
param enableKeyVaultForDiskEncryption bool = false
param enableKeyVaultForTemplateDeployment bool = true
param enableKeyVaultSoftDelete bool = true
param enableKeyVaultRbacAuthorization bool = false
param keyVaultSoftDeleteRetentionInDays int = 7
param keyVaultSKUName string = 'standard'
param keyVaultSKUFamily string = 'A'

param vnetName string
param subnetName string
param webAppFullName string
param databaseServerName string
param sqlDatabaseName string
@secure()
param sqlServerAdminPassword string

param WAGVaultIdentityName string

var vaultName = '${keyVaultName}${uniqueIdentifier}'
var privateDNSZoneName = 'privatelink.vaultcore.azure.net'

resource webApp 'Microsoft.Web/sites@2023-12-01' existing = {
  name: webAppFullName
}

resource databaseServer 'Microsoft.Sql/servers@2023-08-01-preview' existing = {
  name: databaseServerName
}

resource wagVaultIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: WAGVaultIdentityName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: vaultName
  location: location
  properties: {
    enabledForDeployment: enableKeyVaultForDeployments
    enabledForDiskEncryption: enableKeyVaultForDiskEncryption
    enabledForTemplateDeployment: enableKeyVaultForTemplateDeployment
    tenantId: subscription().tenantId
    enableSoftDelete: enableKeyVaultSoftDelete
    softDeleteRetentionInDays: keyVaultSoftDeleteRetentionInDays
    enableRbacAuthorization: enableKeyVaultRbacAuthorization
    sku: {
      name: keyVaultSKUName
      family: keyVaultSKUFamily
    }
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: webApp.identity.principalId
        permissions: {
          keys: []
          secrets: ['Get']
          certificates: []
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: wagVaultIdentity.properties.principalId
        permissions: {
          keys: []
          secrets: ['Get', 'List']
          certificates: ['Get', 'List']
        }
      }
      {
        tenantId: tenant().tenantId
        objectId: keyVaultAdminGroupObjectId
        permissions: {
          keys: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'GetRotationPolicy'
            'SetRotationPolicy'
            'Rotate'
          ]
          secrets: [
            'Get'
            'List'
            'Set'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
          ]
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
    ]
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
  }
}

resource identityDBConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  name: 'IdentityDbConnectionSecret'
  parent: keyVault
  properties: {
    value: 'Server=tcp:${databaseServer.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${databaseServer.properties.administratorLogin};Password=${sqlServerAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

resource contactManagerDBConnectionSecret 'Microsoft.KeyVault/vaults/secrets@2022-11-01' = {
  name: 'ContactManagerDbConnectionSecret'
  parent: keyVault
  properties: {
    value: 'Server=tcp:${databaseServer.name}${environment().suffixes.sqlServerHostname},1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${databaseServer.properties.administratorLogin};Password=${sqlServerAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
  }
}

module privateEndpoint 'helpers/privateLink.bicep' = {
  name: 'privateEndpoint'
  params: {
    location: location
    connectedResourceId: keyVault.id
    privateDnsZoneName: privateDNSZoneName
    groupId: 'vault'
    privateEndpointName: '${keyVault.name}-privateEndpoint'
    subnetName: subnetName
    vnetName: vnetName
  }
}

output keyVaultName string = keyVault.name
output identityDBConnectionSecretURI string = identityDBConnectionSecret.properties.secretUri
output managerDBConnectionSecretURI string = contactManagerDBConnectionSecret.properties.secretUri
