param location string
param localAdminUsername string
@secure()
param localAdminPassword string
param spoke1subnetID string

resource Spoke1VM1Nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'nic-spoke1vm1'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: '10.100.0.5'
          subnet: {
            id: spoke1subnetID
          }
        }
      }
    ]
  }
}

resource Spoke1VM1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'Spoke1VM1'
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
      computerName: 'Spoke1VM1'
      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Spoke1VM1Nic.id
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
  parent: Spoke1VM1
  properties: {
    source: {
      script: 'Add-WindowsFeature -Name DNS -IncludeManagementTools'
    }
  }
}

resource createForwardDNSZone 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'createForwardDNSZone'
  location: location
  parent: Spoke1VM1
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
  parent: Spoke1VM1
  dependsOn: [
    createForwardDNSZone
  ]
  properties: {
    source: {
      script: 'Add-DnsServerResourceRecordA -Name "criticalrecord" -ZoneName "labzone.local" -IPv4Address "10.13.37.10"'
    }
  }
}

resource createDNSConditionalForwarder 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'createDNSConditionalForwarder'
  location: location
  parent: Spoke1VM1
  properties: {
    source: {
      script: 'Add-DnsServerConditionalForwarderZone -Name "file.${environment().suffixes.storage}" -MasterServers 10.200.0.70'
    }
  }
}

resource autoShutdownOnPrem 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-Spoke1VM1'
  location: location
  properties: {
    status: 'Enabled'
    dailyRecurrence: {
      time: '17:00'
    }
    timeZoneId: 'UTC'
    targetResourceId: Spoke1VM1.id
    taskType: 'ComputeVmShutdownTask'
  }
}
