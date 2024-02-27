param location string

resource BastionHub 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'BastionHub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'gatewaysubnet'
        properties: {
          addressPrefix: '10.200.0.0/27'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.200.0.64/26'
        }
      }
    ]
  }
}

resource BastionSpoke1 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'BastionSpoke1-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.1.0/24'
      ]
    }
    subnets: [
      {
        name: 'BastionSpoke1-snet'
        properties: {
          addressPrefix: '10.200.1.0/24'
        }
      }
    ]
  }
}

resource BastionSpoke2 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'BastionSpoke2-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.2.0/24'
      ]
    }
    subnets: [
      {
        name: 'BastionSpoke2-snet'
        properties: {
          addressPrefix: '10.200.2.0/24'
        }
      }
    ]
  }
}

output HubID string = BastionHub.id
output Spoke1ID string = BastionSpoke1.id
output Spoke2ID string = BastionSpoke2.id
output HubBastionSubnetID string = BastionHub.properties.subnets[1].id
output Spoke1SubnetID string = BastionSpoke1.properties.subnets[0].id
output Spoke2SubnetID string = BastionSpoke2.properties.subnets[0].id
