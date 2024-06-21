param rgName string
param location string
param appInsightsName string
param vnetName string
param webSubnetName string
param endpointsSubnetName string
param uniqueIdentifier string 
param appServicePlanName string
@allowed(['S1', 'S2', 'S3'])
param appServicePlanSku string = 'S1'
param webAppName string 
param environment string = 'Dev'
param identityDBConnectionStringKey string = 'DefaultConnection'
param applicationDbConnectionStringKey string = 'MyContactManager'

var workerRuntime = 'dotnet'
var webAppFullName = '${webAppName}-${uniqueIdentifier}'
var privateDnsZoneName = 'privatelink.azurewebsites.net'
var identityDBConnectionStringValue = 'TBD later:ContactWebIdentityDBConnectionString'
var managerDBConnectionStringValue = 'TBD later:ContactWebApplicationDBConnectionString'

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource webSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: webSubnetName
  parent: virtualNetwork
}

resource endpointsSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: endpointsSubnetName
  parent: virtualNetwork
}

resource hostingPlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: '${appServicePlanName}-${uniqueIdentifier}'
  location: location
  sku: {
    name: appServicePlanSku
  }
}

var appServicePropertiesAndConfig = {
  serverFarmId: hostingPlan.id
  httpsOnly: true
  virtualNetworkSubnetId: webSubnet.id
  publicNetworkAccess: 'Enabled' //to secure this web app, set this to 'Disabled', you will need a WAG or Front Door or another ingress
  siteConfig: {
    metadata: [
      {
        name:'CURRENT_STACK'
        value:workerRuntime
      }
    ]
    netFrameworkVersion:'v6.0'
    ftpsState: 'FtpsOnly'
    minTlsVersion: '1.2'
    http20Enabled: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppFullName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: appServicePropertiesAndConfig
}

resource appSettings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'appsettings'
  kind: 'string'
  parent: webApp
  properties: {
    ENVIRONMENT: environment
    REGION: location
    'APPINSIGHTS:CONNECTIONSTRING': applicationInsights.properties.ConnectionString
  }
}

resource connectionStrings 'Microsoft.Web/sites/config@2023-12-01' = {
  name: 'connectionstrings'
  kind: 'string'
  parent: webApp
  properties: {
    '${identityDBConnectionStringKey}': { value: identityDBConnectionStringValue, type: 'SQLAzure' }
    '${applicationDbConnectionStringKey}': { value: managerDBConnectionStringValue, type: 'SQLAzure' }
  }
}

module privateLink 'helpers/privateLink.bicep' = {
  name: '${webAppName}-privateLink'
  scope: resourceGroup(rgName)
  params: {
    location: location
    privateEndpointName: '${webAppFullName}-privateEndpoint'
    vnetName: virtualNetwork.name
    subnetName: endpointsSubnet.name
    connectedResourceId: webApp.id
    groupId: 'sites'
    privateDnsZoneName: privateDnsZoneName
  }
}

output webAppFullName string = webApp.name
output webAppMIPrincipalId string = webApp.identity.principalId
output webAppPrivateIPAddress string = privateLink.outputs.privateIPAddress
