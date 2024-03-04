param location string
param natGatewayId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-lab'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.13.37.0/24'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.13.37.0/27'
        }
      }
      {
        name: 'snet-lab'
        properties: {
          addressPrefix: '10.13.37.128/25'
          natGateway: {
            id: natGatewayId
          }
        }
      }
    ]
  }
}

output bastionSubnetId string = vnet.properties.subnets[0].id
output vmSubnetId string = vnet.properties.subnets[1].id
