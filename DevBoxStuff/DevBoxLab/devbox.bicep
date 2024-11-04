param devCenterName string
param devPrincipalId string
param location string

resource devCenter 'Microsoft.DevCenter/devcenters@2024-08-01-preview' = {
  name: devCenterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: devCenterName
    networkSettings: {
      microsoftHostedNetworkEnableStatus: 'Enabled'
    }
    devBoxProvisioningSettings: {
      installAzureMonitorAgentEnableStatus: 'Enabled'
    }
  }
}

resource devBoxDefinition 'Microsoft.DevCenter/devcenters/devboxdefinitions@2024-08-01-preview' = {
  name: 'defaultDefinition'
  parent: devCenter
  location: location
  properties:{
    imageReference: {
      id: '${devCenter.id}/images/microsoftwindowsdesktop_windows-ent-cpc_win11-24h2-ent-cpc-m365'
    }
    sku: {
      name: 'general_i_8c32gb256ssd_v2'
    }
    hibernateSupport: 'Enabled'
  }
}

resource devboxProject 'Microsoft.DevCenter/projects@2024-08-01-preview' = {
  name: 'defaultProject'
  location: location
  properties: {
    devCenterId: devCenter.id
    maxDevBoxesPerUser: 1
  }
}

resource projectPool 'Microsoft.DevCenter/projects/pools@2024-08-01-preview' = {
  name: 'defaultPool'
  location: location
  parent: devboxProject
  properties: {
    devBoxDefinition: devBoxDefinition
    devBoxDefinitionType: 'Reference'
    devBoxDefinitionName: devBoxDefinition.name
    licenseType: 'Windows_Client'
    localAdministrator: 'Enabled'
    stopOnDisconnect: {
      status: 'Enabled'
      gracePeriodMinutes: 60
    }
    virtualNetworkType: 'Managed'
    managedVirtualNetworkRegions: [
      location
    ]
  }
}

resource assignDev 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'assignDevDevUserRole'
  scope: devboxProject
  properties: {
    principalId: devPrincipalId
    roleDefinitionId: '45d50f46-0b78-4001-a660-4198cbe8cd05'
  }
}
