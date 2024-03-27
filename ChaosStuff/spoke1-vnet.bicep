param location string
param azureFirewallPrivateIP string

resource routeTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: 'rt-spoke1'
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

resource Spoke1 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-spoke1'
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
          routeTable: {
            id: routeTable.id
          }
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

output spoke1vnetID string = Spoke1.id
output spoke1subnetID string = Spoke1.properties.subnets[0].id
