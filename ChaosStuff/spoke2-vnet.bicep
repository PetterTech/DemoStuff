param location string
param azureFirewallPrivateIP string
param spoke2iprange string
param spoke2defaultsubnetrange string

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-spoke2'
  location: location
  properties: {
    routes: [
      {
      name: 'default'
      properties: {
        addressPrefix: '0.0.0.0/0'
        nextHopType: 'VirtualAppliance'
        nextHopIpAddress: azureFirewallPrivateIP
        }
      }
    ]
  }
}

resource spoke2vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-Spoke2'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke2iprange
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: spoke2defaultsubnetrange
          routeTable: {
            id: routeTable.id
          }
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        '10.200.0.70'
      ]
    }
  }
}

output spoke2vnetID string = spoke2vnet.id
output spoke2subnetID string = spoke2vnet.properties.subnets[0].id
output spoke2iprange string = spoke2vnet.properties.addressSpace.addressPrefixes[0]
