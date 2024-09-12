param location string
param bastionPublicIPAddressName string
param bastionSubnetID string
param bastionName string
param basSkuName string

resource bastionPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: bastionPublicIPAddressName
  location: location
  sku: {
    name: basSkuName
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          publicIPAddress: {
            id: bastionPublicIPAddress.id
          }
          subnet: {
            id: bastionSubnetID
          }
        }
      }
    ]
  }
}
