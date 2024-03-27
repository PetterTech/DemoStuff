param location string
param localAdminUsername string
@secure()
param localAdminPassword string
param spoke2subnetID string

resource Spoke2VM1Nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-Spoke2VM1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spoke2subnetID
          }
        }
      }
    ]
  }
}

resource Spoke2VM1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'Spoke2VM1'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4s_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    osProfile: {
      computerName: 'Spoke2VM1'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Spoke2VM1Nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }     
  }
}

resource installIISRole 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'installIISRole'
  location: location
  parent: Spoke2VM1
  properties: {
    source: {
      script: 'Install-WindowsFeature -name Web-Server -IncludeManagementTools'
    }
  }
}

resource autoShutdownSpoke 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-Spoke2VM1'
  location: location
  properties: {
    status: 'Enabled'
    dailyRecurrence: {
      time: '17:00'
    }
    timeZoneId: 'UTC'
    targetResourceId: Spoke2VM1.id
    taskType: 'ComputeVmShutdownTask'
  }
}
