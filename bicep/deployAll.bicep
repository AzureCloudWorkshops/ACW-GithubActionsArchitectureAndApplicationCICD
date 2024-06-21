param location string = 'centralus'
param rgName string
param environment string = 'dev'
param vnetName string 
param privateIPPrefix int
param endpointsSubnetName string
param endpointsSubnetIPZone int
param webSubnetName string
param webSubnetIPZone int
//app service
param logAnalyticsWorkspaceName string
param appInsightsName string
param uniqueIdentifier string
param appServicePlanName string
@allowed([
  'S1' 
  'S2'
  'S3'
])
param appServicePlanSku string
param webAppName string
param applicationDbConnectionStringKey string
param identityDBConnectionStringKey string
//database
param allowClientIPAddressSQLDbAccess bool = false
param clientIPAddress string = '10.10.10.10'
param sqlDatabaseName string
param sqlServerName string
param sqlServerAdminLogin string
@secure()
param sqlServerAdminPassword string

//vault
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

//wag
param WAGVaultIdentityName string

//storage?

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
}

module vnet 'VNetAndSubnets.bicep' = {
  name: vnetName
  scope: resourceGroup
  params: {
    location: location
    vnetName: vnetName
    privateIPPrefix: privateIPPrefix
    endpointsSubnetName: endpointsSubnetName
    endpointsSubnetIPZone: endpointsSubnetIPZone
    webSubnetName: webSubnetName
    webSubnetIPZone: webSubnetIPZone
  }
}

module sqldatabase 'AzureSQL.bicep' = {
  name: 'sqldatabase'
  scope: resourceGroup
  params: {
    location: location
    vnetName: vnet.outputs.vnetName
    endpointsSubnetName: endpointsSubnetName
    uniqueIdentifier: uniqueIdentifier
    allowClientIPAddressAccess: allowClientIPAddressSQLDbAccess
    clientIPAddress: clientIPAddress
    sqlDatabaseName: sqlDatabaseName
    sqlServerName: sqlServerName
    sqlServerAdminLogin: sqlServerAdminLogin
    sqlServerAdminPassword: sqlServerAdminPassword
  }
}

module logAnalytics 'LogAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

module appInsights 'AppInsights.bicep' = {
  name: appInsightsName
  scope: resourceGroup
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module appServiceAndPlan 'AppService.bicep' = {
  name: appServicePlanName
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appServicePlanSku: appServicePlanSku
    webAppName: webAppName
    appInsightsName: appInsights.outputs.applicationInsightsName
    uniqueIdentifier: uniqueIdentifier
    vnetName: vnet.outputs.vnetName
    webSubnetName: webSubnetName
    endpointsSubnetName: endpointsSubnetName
    rgName: rgName
    applicationDbConnectionStringKey: applicationDbConnectionStringKey
    identityDBConnectionStringKey: identityDBConnectionStringKey
    environment: environment
  }
}

module keyVault 'KeyVault.bicep' = {
  name: keyVaultName
  scope: resourceGroup
  params: {
    location: location
    keyVaultName: keyVaultName
    keyVaultAdminGroupObjectId: keyVaultAdminGroupObjectId
    enableKeyVaultForDeployments: enableKeyVaultForDeployments
    enableKeyVaultForDiskEncryption: enableKeyVaultForDiskEncryption
    enableKeyVaultForTemplateDeployment: enableKeyVaultForTemplateDeployment
    enableKeyVaultSoftDelete: enableKeyVaultSoftDelete
    enableKeyVaultRbacAuthorization: enableKeyVaultRbacAuthorization
    keyVaultSoftDeleteRetentionInDays: keyVaultSoftDeleteRetentionInDays
    keyVaultSKUName: keyVaultSKUName
    keyVaultSKUFamily: keyVaultSKUFamily
    databaseServerName: sqldatabase.outputs.sqlServerName
    sqlDatabaseName: sqldatabase.outputs.sqlDBName
    sqlServerAdminPassword: sqlServerAdminPassword
    uniqueIdentifier: uniqueIdentifier
    webAppFullName: appServiceAndPlan.outputs.webAppFullName
    vnetName: vnet.outputs.vnetName
    subnetName: endpointsSubnetName
    WAGVaultIdentityName: WAGVaultIdentityName
  }
}

module updateAppServiceSettings 'AppServiceUpdateConnectionStrings.bicep' = {
  name: 'updateAppServiceConnectionStrings'
  scope: resourceGroup
  params: {
    webAppName: appServiceAndPlan.outputs.webAppFullName
    defaultDBSecretURI: keyVault.outputs.identityDBConnectionSecretURI
    managerDBSecretURI: keyVault.outputs.managerDBConnectionSecretURI
    identityDBConnectionStringKey: identityDBConnectionStringKey
    managerDBConnectionStringKey: applicationDbConnectionStringKey
  }
}
