param location string

resource hubvnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-Hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.200.0.0/26'
        }
      }
      {
        name: 'Inbound'
        properties: {
          addressPrefix: '10.200.0.64/26'
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: 'Outbound'
        properties: {
          addressPrefix: '10.200.0.128/26'
          delegations: [
            {
              name: 'Microsoft.Network.dnsResolvers'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.200.0.192/26'
        }
      }
    ]
  }
}

output vnetID string = hubvnet.id
output firewallSubnetID string = hubvnet.properties.subnets[0].id
output inboundSubnetID string = hubvnet.properties.subnets[1].id
output outboundSubnetID string = hubvnet.properties.subnets[2].id
output bastionSubnetID string = hubvnet.properties.subnets[3].id
