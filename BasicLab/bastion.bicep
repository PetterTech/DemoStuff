param location string
param bastionSubnetId string

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'pip-labBastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'bas-labBastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: bastionSubnetId
          }
        }
      }
    ]
  }
}
