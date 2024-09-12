param location string = resourceGroup().location
param projectName string
param vm1Id string
param vm2Id string

resource redeployVM1 'Microsoft.Chaos/experiments@2024-03-22-preview' = {
  name: 'exp-${projectName}-redeployVM1'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    selectors: [
      {
        id: 'selector1'
        type: 'List'
        targets: [{
          id: '${vm1Id}/providers/Microsoft.Chaos/targets/Microsoft-VirtualMachine'
          type: 'ChaosTarget'
        }]
      }
    ]
    steps: [
      {
        name: 'step1'
        branches : [
          {
            name: 'branch1'
            actions: [
              {
                name: 'urn:csci:microsoft:virtualMachine:redeploy/1.0'
                type: 'discrete'
                parameters: [
                ]
                selectorId: 'selector1'
              }
            ]
          }
        ]
      }
    ]
  }
}

resource shutdownVM2 'Microsoft.Chaos/experiments@2024-03-22-preview' = {
  name: 'exp-${projectName}-shutdownVM2'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    selectors: [
      {
        id: 'selector1'
        type: 'List'
        targets: [{
          id: '${vm2Id}/providers/Microsoft.Chaos/targets/Microsoft-VirtualMachine'
          type: 'ChaosTarget'
        }]
      }
    ]
    steps: [
      {
        name: 'step1'
        branches : [
          {
            name: 'branch1'
            actions: [
              {
                name: 'urn:csci:microsoft:virtualMachine:shutdown/1.0'
                type: 'continuous'
                parameters: [
                  {
                    key: 'abruptShutdown'
                    value: 'false'
                  }
                ]
                duration: 'PT10M'
                selectorId: 'selector1'
              }
            ]
          }
        ]
      }
    ]
  }
}


output redeployVM1Id string = redeployVM1.identity.principalId
output shutdownVM2Id string = shutdownVM2.identity.principalId
