targetScope = 'resourceGroup'

param location string = resourceGroup().location

resource vnetmanager 'Microsoft.Network/networkManagers@2024-01-01' = {
  name: 'vnm-demoManager'
  location: location
  properties: {
    networkManagerScopeAccesses: []
    networkManagerScopes: {
      subscriptions: [
        '/subscriptions/${subscription().subscriptionId}'
      ]
    }
  }
}

resource ipampool 'Microsoft.Network/networkManagers/ipamPools@2024-01-01-preview' = {
  name: 'ipamPool'
  location: location
  parent: vnetmanager
  properties: {
    addressPrefixes: [
      '10.0.0.0/20'
    ]
    displayName: 'ipamPool'
  }
}

resource staticcidr 'Microsoft.Network/networkManagers/ipamPools/staticCidrs@2024-01-01-preview' = {
  name: 'OnPremCIDR'
  parent: ipampool
  properties: {
    addressPrefixes: [
      '10.0.4.0/22'
    ]
    description: 'On-prem network'
  }
}

resource testnet1 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: 'vnet-testnet1'
  location: location
  properties: {
    addressSpace: {
      ipamPoolPrefixAllocations: [
        {
          numberOfIpAddresses: '256'
          pool: {
            id: ipampool.id
          }
          allocatedAddressPrefixes: [
            '10.0.0.0/24'
          ]
        }
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          ipamPoolPrefixAllocations: [
            {
              numberOfIpAddresses: '128'
              pool: {
                id: ipampool.id
              }
              allocatedAddressPrefixes: [
                '10.0.0.0/25'
              ]
            }
          ]
        }
      }
      {
        name: 'subnet-default1'
        properties: {
          ipamPoolPrefixAllocations: [
            {
              numberOfIpAddresses: '128'
              pool: {
                id: ipampool.id
              }
              allocatedAddressPrefixes: [
                '10.0.0.128/25'
              ]
            }
          ]
        }
      }
    ]
  }
}
