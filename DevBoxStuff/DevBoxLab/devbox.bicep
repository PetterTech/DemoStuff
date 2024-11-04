param projectName string
param devPrincipalId string
param location string
param vmSubnetId string

resource devCenter 'Microsoft.DevCenter/devcenters@2024-08-01-preview' = {
  name: '${projectName}-devCenter'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: '${projectName}-devCenter'
    networkSettings: {
      microsoftHostedNetworkEnableStatus: 'Enabled'
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: 'Enabled'
    }
  }
}

resource devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2024-08-01-preview' = {
  name: '${projectName}-definition'
  parent: devCenter
  location: location
  properties:{
    imageReference: {
      id: '${devCenter.id}/galleries/default/images/microsoftwindowsdesktop_windows-ent-cpc_win11-24h2-ent-cpc-m365'
    }
    sku: {
      name: 'general_i_8c32gb256ssd_v2'
    }
    hibernateSupport: 'Enabled'
  }
}

resource devboxProject 'Microsoft.DevCenter/projects@2024-08-01-preview' = {
  name: '${projectName}-project'
  location: location
  properties: {
    devCenterId: devCenter.id
    maxDevBoxesPerUser: 1
  }
}

resource networkConnection 'Microsoft.DevCenter/networkConnections@2024-08-01-preview' = {
  name: '${projectName}-vnetconnection'
  location: location
  properties: {
    domainJoinType: 'AzureADJoin'
    networkingResourceGroupName: 'rg-${projectName}-network'
    subnetId: vmSubnetId
  }
}

resource devCenterNetwork 'Microsoft.DevCenter/devcenters/attachednetworks@2024-08-01-preview' = {
  name: networkConnection.name
  parent: devCenter
  properties: {
    networkConnectionId: networkConnection.id
  }
}

resource projectPool 'Microsoft.DevCenter/projects/pools@2024-08-01-preview' = {
  name: '${projectName}-pool'
  parent: devboxProject
  location: location
  properties: {
    devBoxDefinitionType: 'Reference'
    devBoxDefinitionName: devBoxDefinition.name
    networkConnectionName: networkConnection.name
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
    stopOnDisconnect: {
      status: 'Enabled'
      gracePeriodMinutes: 60
    }
    singleSignOnStatus: 'Disabled'
    displayName: 'defaultPool'
    virtualNetworkType:'Unmanaged'
  }
}

resource projectPoolSchedule 'Microsoft.DevCenter/projects/pools/schedules@2024-08-01-preview' = {
  parent: projectPool
  name: 'default'
  properties: {
    type: 'StopDevBox'
    frequency: 'Daily'
    time: '19:00'
    timeZone: 'Europe/Oslo'
    state: 'Enabled'
  }
}

resource devBoxUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: '45d50f46-0b78-4001-a660-4198cbe8cd05'
  scope: subscription()
}

resource assignDev 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, devPrincipalId, devBoxUserRoleDefinition.id)
  scope: devboxProject
  properties: {
    principalType: 'User'
    principalId: devPrincipalId
    roleDefinitionId: devBoxUserRoleDefinition.id
  }
}
