param location string = resourceGroup().location
param vnetName string = 'ghatrainingvnet'
param privateIPPrefix int = 125
param endpointsSubnetName string = 'endpoints'
param endpointsSubnetIPZone int = 10
param webSubnetName string = 'web'
param webSubnetIPZone int = 5

var addressPrefix = '10.${privateIPPrefix}.0.0/16'
var endpointsSubnetPrefix = '10.${privateIPPrefix}.${endpointsSubnetIPZone}.0/24'
var webSubnetPrefix = '10.${privateIPPrefix}.${webSubnetIPZone}.0/24'

/* Create a virtual network with two subnets */
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: webSubnetPrefix
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: endpointsSubnetName
        properties: {
          addressPrefix: endpointsSubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = virtualNetwork.id
output vnetName string = virtualNetwork.name
