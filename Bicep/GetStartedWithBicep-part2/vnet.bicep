param myLocation string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'labvnet'
  location: myLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.13.37.0/24'
      ]
    }
    subnets: [
      {
        name: 'labsubnet'
        properties: {
          addressPrefix: '10.13.37.0/24'
        }
      }
    ]
  }
}

output subnetid string = vnet.properties.subnets[0].id
