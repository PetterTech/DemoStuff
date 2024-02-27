param location string
param localAdminUsername string
@secure()
param localAdminPassword string
param onpremsubnetID string
param spokesubnetID string

resource OnPremVMNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'OnPremVMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.100.0.5'
          subnet: {
            id: onpremsubnetID
          }
        }
      }
    ]
  }
}

resource SpokeVMNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'SpokeVMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spokesubnetID
          }
        }
      }
    ]
  }
}

resource OnPremVM 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'OnPremVM'
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
      computerName: 'OnPremVM'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: OnPremVMNic.id
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

resource installDNSRole 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'installDNSRole'
  location: location
  parent: OnPremVM
  properties: {
    source: {
      script: 'Add-WindowsFeature -Name DNS -IncludeManagementTools'
    }
  }
}

resource createForwardDNSZone 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'createForwardDNSZone'
  location: location
  parent: OnPremVM
  dependsOn: [
    installDNSRole
  ]
  properties: {
    source: {
      script: 'Add-DnsServerPrimaryZone -Name "labzone.local" -ZoneFile "labzone.local.dns"'
    }
  }
}

resource createDNSRecords 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'createDNSRecords'
  location: location
  parent: OnPremVM
  dependsOn: [
    createForwardDNSZone
  ]
  properties: {
    source: {
      script: 'Add-DnsServerResourceRecordA -Name "onpremhost" -ZoneName "labzone.local" -IPv4Address "10.13.37.10"'
    }
  }
}

resource SpokeVM 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'SpokeVM'
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
      computerName: 'SpokeVM'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: SpokeVMNic.id
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

resource autoShutdownOnPrem 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-OnPremVM'
  location: location
  properties: {
    status: 'Enabled'
    dailyRecurrence: {
      time: '17:00'
    }
    timeZoneId: 'UTC'
    targetResourceId: OnPremVM.id
    taskType: 'ComputeVmShutdownTask'
  }
}

resource autoShutdownSpoke 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-SpokeVM'
  location: location
  properties: {
    status: 'Enabled'
    dailyRecurrence: {
      time: '17:00'
    }
    timeZoneId: 'UTC'
    targetResourceId: SpokeVM.id
    taskType: 'ComputeVmShutdownTask'
  }
}

output onPremVMID string = OnPremVM.id
