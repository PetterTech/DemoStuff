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
  }
}

resource vNetName_bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: vNet
  name: bastionSubnetName
  properties: {
    addressPrefix: vNetBastionSubnetAddressPrefix
  }
  dependsOn: [
    vNetName_vNetSubnetName
  ]
}

resource vNetName_vNetSubnetName 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: vNet
  name: vNetSubnetName
  properties: {
    addressPrefix: vNetSubnetAddressPrefix
    natGateway: {
      id: natGatewayId
    }
  }
}

output vmSubnetId string = vNetName_vNetSubnetName.id
output nsgId string = nsg.id
