param location string
param nsgName string
param vNetName string
param vNetAddressPrefix string
param vNetSubnetName string
param vNetSubnetAddressPrefix string
param bastionSubnetName string
param vNetBastionSubnetAddressPrefix string
param natGatewayId string



resource nsg 'Microsoft.Network/networkSecurityGroups@2021-08-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vNet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: vNetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: vNetSubnetName
        properties: {
          addressPrefix: vNetSubnetAddressPrefix
          natGateway: {
            id: natGatewayId
          }
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: vNetBastionSubnetAddressPrefix
        }
      }
    ]
  }
}

resource vmsubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: vNetSubnetName
  parent: vNet
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-01-01' existing = {
  name: bastionSubnetName
  parent: vNet
}

output vmSubnetId string = vmsubnet.id
output bastionSubnetId string = bastionSubnet.id
output nsgId string = nsg.id
