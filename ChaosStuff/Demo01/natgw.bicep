param location string
param natGatewayPublicIPAddressName string
param natGatewayName string

resource natGatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: natGatewayPublicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}
resource natGateway 'Microsoft.Network/natGateways@2021-05-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natGatewayPublicIPAddress.id
      }
    ]
  }
}

output natGatewayId string = natGateway.id
