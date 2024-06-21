param nicId string

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-11-01' existing = {
  name: nicId
}

output ipAddress string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
