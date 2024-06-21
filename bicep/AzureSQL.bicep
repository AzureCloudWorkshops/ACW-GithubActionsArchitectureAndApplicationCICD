@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the Virtual Network')
param vnetName string
@description('Name of the Subnet to deploy the Private Endpoint')
param endpointsSubnetName string

@description('Provide a unique datetime and initials string to make your instances unique. Use only lower case letters and numbers')
@minLength(11)
@maxLength(11)
param uniqueIdentifier string

@description('Name of the SQL Db Server')
param sqlServerName string

@description('Name of the Sql Database')
param sqlDatabaseName string

@description('Admin UserName for the SQL Server')
param sqlServerAdminLogin string

@description('Admin Password for the SQL Server')
@secure()
param sqlServerAdminPassword string

@description('Allow access to the SQL Server from a Client IP Address')
param allowClientIPAddressAccess bool = false

@description('Your Client IP Address to allow access to the SQL Server')
param clientIPAddress string = '10.10.10.10'

var sqlDBServerName = '${sqlServerName}${uniqueIdentifier}'
var dbSKU = 'Basic'
var dbCapacity = 5
var privateDnsZoneName = 'privatelink${environment().suffixes.sqlServerHostname}'

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  parent: vnet
  name: endpointsSubnetName
}

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlDBServerName
  location: location
  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource sqlServerFirewallRuleAllAzureServices 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowClientIPAddressAccess) {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource sqlServerFirewallRuleClientIP 'Microsoft.Sql/servers/firewallRules@2022-05-01-preview' = if (allowClientIPAddressAccess) {
  parent: sqlServer
  name: 'MyIPCanAccessServer'
  properties: {
    startIpAddress: clientIPAddress
    endIpAddress: clientIPAddress
  }
}

resource sqlDB 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: dbSKU
    capacity: dbCapacity
  }
  properties: {
    requestedBackupStorageRedundancy: 'local'
  }
}

module privateLink 'helpers/privateLink.bicep' = {
  name: '${sqlDBServerName}-privateLink'
  params: {
    location: location
    privateEndpointName: '${sqlDBServerName}-privateEndpoint'
    vnetName: vnet.name
    subnetName: subnet.name
    connectedResourceId: sqlServer.id
    groupId: 'sqlServer'
    privateDnsZoneName: privateDnsZoneName
  }
}

output sqlServerName string = sqlServer.name
output sqlDBName string = sqlDB.name
output sqlServerEndpointPrivateIP string = privateLink.outputs.privateIPAddress
