param location string
param firewallsubnetID string

resource publicIP 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'pip-AzureFirewall'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: 'Standard'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: 'hub-AzureFirewallPolicy'
  location: location
  properties: {
    threatIntelMode: 'Alert'
    sku: {
      tier: 'Standard'
    }
  }
}

resource azureFirewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: 'hub-AzureFirewall'
  location: location
  properties: {
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'AzureFirewallIpConfiguration'
        properties: {
          subnet: {
            id: firewallsubnetID
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

output azureFirewallPrivateIP string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
