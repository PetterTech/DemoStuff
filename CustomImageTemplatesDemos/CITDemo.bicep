targetScope = 'resourceGroup'

@description('The Entra ID group to whom will be assigned the application group')
param groupID string
param location string = 'northeurope'

resource natGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'CITDemo-natgateway-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-09-01' = {
  name: 'CITDemo-natgateway'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natGatewayPublicIp.id
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'CITDemo-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.13.37.0/24'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.13.37.0/27'
        }
      }
      {
        name: 'default'
        properties: {
          addressPrefix: '10.13.37.128/25'
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: 'CITDemo-bastion-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-09-01' = {
  name: 'CITDemo-bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
       {
         name: 'bastionIpConfig'
         properties: {
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
         }
       }
    ]
  }
}

resource avdHostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: 'CITDemo-HostPool'
  location: location
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
  }
}

resource avdApplicationGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: 'CITDemo-AppGroup'
  location: location
  properties: {
    friendlyName: 'CITDemo-AppGroup'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: avdHostPool.id
  }
}

resource avdWorkspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: 'CITDemo-Workspace'
  location: location
  properties: {
    friendlyName: 'CITDemo-Workspace'
  }
}

resource avdRoleId 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
}

resource avdAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(avdApplicationGroup.id, groupID, avdRoleId.id)
  scope: avdApplicationGroup
  properties: {
    principalId: groupID
    roleDefinitionId: avdRoleId.id
    principalType: 'Group'
  }
}
