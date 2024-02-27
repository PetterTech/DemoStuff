param location string

resource onpremvnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'Onprem'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.100.0.0/26'
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        '10.100.0.5'
        '1.1.1.1'
      ]
    }
  }
}

output vnetID string = onpremvnet.id
output onpremsubnetID string = onpremvnet.properties.subnets[0].id
