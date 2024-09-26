param location string = resourceGroup().location
param projectName string
param managedIdentityClientId string

resource vm1 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm1'
}

resource vm2 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm2'
}

resource vm3 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm3'
}

resource chaoServiceTarget1 'Microsoft.Chaos/targets@2024-03-22-preview' = {
  name: 'Microsoft-VirtualMachine'
  location: location
  scope: vm1
  properties: {}
  resource vmShutdown 'capabilities' = {
    name: 'Shutdown-1.0'
  }
  resource vmRedeploy 'capabilities' = {
    name: 'Redeploy-1.0'
  }
}

resource chaosServiceTarget2 'Microsoft.Chaos/targets@2024-03-22-preview' = {
  name: 'Microsoft-VirtualMachine'
  location: location
  scope: vm2
  properties: {}
  resource vmShutdown 'capabilities' = {
    name: 'Shutdown-1.0'
  }
  resource vmRedeploy 'capabilities' = {
    name: 'Redeploy-1.0'
  }
}

resource chaosServiceTarget3 'Microsoft.Chaos/targets@2024-03-22-preview' = {
  name: 'Microsoft-VirtualMachine'
  location: location
  scope: vm3
  properties: {}
  resource vmShutdown 'capabilities' = {
    name: 'Shutdown-1.0'
  }
  resource vmRedeploy 'capabilities' = {
    name: 'Redeploy-1.0'
  }
}

resource vm1ChaosAgent 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  name: 'ChaosAgent'
  location: location
  parent: vm1
  properties: {
    publisher: 'Microsoft.Azure.Chaos'
    type: 'ChaosWindowsAgent'
    settings: {
      profile: reference('${vm1.id}/providers/Microsoft.Chaos/targets/Microsoft-Agent').agentProfileId
      'auth.msi.clientid': managedIdentityClientId
      appinsightskey: ''
    }
  }
}

resource chaosAgentTarget1 'Microsoft.Chaos/targets@2024-03-22-preview' = {
  name: 'Microsoft-Agent'
  location: location
  scope: vm1
  properties: {}
  dependsOn: [
    vm1ChaosAgent
  ]
}

resource vm1Capability_DiskPressure 'Microsoft.Chaos/targets/capabilities@2024-03-22-preview' = {
  name: 'DiskIOPressure-1.1'
  parent: chaosAgentTarget1
}
