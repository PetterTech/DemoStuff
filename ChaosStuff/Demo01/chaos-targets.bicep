param location string = resourceGroup().location
param projectName string

resource vm1 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm1'
}

resource vm2 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm2'
}

resource vm3 'Microsoft.Compute/virtualMachines@2024-03-01' existing = {
  name: '${projectName}-vm3'
}

resource chaosTarget1 'Microsoft.Chaos/targets@2024-03-22-preview' = {
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

resource chaosTarget2 'Microsoft.Chaos/targets@2024-03-22-preview' = {
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

resource chaosTarget3 'Microsoft.Chaos/targets@2024-03-22-preview' = {
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
