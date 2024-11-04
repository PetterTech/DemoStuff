param location string

resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-natGateway'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: 'ng-natGateway'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
  }
}

output natGatewayId string = natGateway.id
