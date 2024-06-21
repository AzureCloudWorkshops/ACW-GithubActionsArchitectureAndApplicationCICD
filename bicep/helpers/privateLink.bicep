param location string = resourceGroup().location
param privateEndpointName string
param vnetName string
param subnetName string
param connectedResourceId string
param groupId string
param privateDnsZoneName string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${virtualNetwork.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}



resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnet.id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: connectedResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
  dependsOn: [
    subnet
  ]
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpoint.name}-group'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

module networkInterfaceIP 'getNICIPAddress.bicep' = {
  name: 'getNetworkIP'
  params: {
    nicId: last(split(privateEndpoint.properties.networkInterfaces[0].id, '/'))
  }
}

output nicId string = last(split(privateEndpoint.properties.networkInterfaces[0].id, '/'))
output privateIPAddress string = networkInterfaceIP.outputs.ipAddress
output privateEndpointId string = privateEndpoint.id
