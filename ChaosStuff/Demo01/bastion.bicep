param location string
param bastionPublicIPAddressName string
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
