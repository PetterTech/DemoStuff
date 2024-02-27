param location string

resource spokevnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'Spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.201.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.201.0.0/26'
        }
      }
    ]
  }
}

output vnetID string = spokevnet.id
output spokesubnetID string = spokevnet.properties.subnets[0].id
