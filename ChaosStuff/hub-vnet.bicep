param location string
param hubiprange string
param firewallsubnetrange string
param dnsinboundrange string
param dnsoutboundrange string
param bastionrange string


resource hubvnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-Hub'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubiprange
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: firewallsubnetrange
        }
      }
      {
        name: 'Inbound'
        properties: {
          addressPrefix: dnsinboundrange
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
          addressPrefix: dnsoutboundrange
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
          addressPrefix: bastionrange
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
