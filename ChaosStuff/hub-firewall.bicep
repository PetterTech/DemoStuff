param location string
param firewallsubnetID string
param spoke1iprange string
param spoke2iprange string

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

resource spoke1ipgroup 'Microsoft.Network/ipGroups@2023-09-01' = {
  name: 'spoke1ipgroup'
  location: location
  properties: {
    ipAddresses: [
      spoke1iprange
    ]
  }
}

resource spoke2ipgroup 'Microsoft.Network/ipGroups@2023-09-01' = {
  name: 'spoke2ipgroup'
  location: location
  properties: {
    ipAddresses: [
      spoke2iprange
    ]
  }
}

output azureFirewallPrivateIP string = azureFirewall.properties.ipConfigurations[0].properties.privateIPAddress
output azureFirewallPolicyName string = firewallPolicy.name
output spoke1ipgroupID string = spoke1ipgroup.id
output spoke2ipgroupID string = spoke2ipgroup.id
