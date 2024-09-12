param location string
param projectName string
param nsgId string
param vmsubnetId string
param lbName string
param lbBackendPoolName string
param vmSize string
param OSVersion string
param vmStorageAccountType string
param adminUsername string
@secure()
param adminPassword string
param securityProfileJson object

resource vm_NIC 'Microsoft.Network/networkInterfaces@2021-08-01' = [for i in range(0, 3): {
  name: 'nic-${projectName}-vm${(i + 1)}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmsubnetId
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbBackendPoolName)
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}
]

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(1, 3): {
  name: '${projectName}-vm${i}'
  location: location
  zones: [
    string(i)
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmStorageAccountType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic-${projectName}-vm${i}')
        }
      ]
    }
    osProfile: {
      computerName: '${projectName}-vm${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: securityProfileJson
  }
  dependsOn: [
    vm_NIC
  ]
}
]

resource vm_InstallWebServer 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = [for i in range(0, 3): {
  name: '${projectName}-vm${(i + 1)}/InstallWebServer'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      commandToExecute: 'powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item \'C:\\inetpub\\wwwroot\\iisstart.htm\' && powershell.exe Add-Content -Path \'C:\\inetpub\\wwwroot\\iisstart.htm\' -Value $(\'Hello World from \' + $env:computername)'
    }
  }
  dependsOn: [
    vm
  ]
}
]

output vm1Id string = vm[0].id
output vm2Id string = vm[1].id
output vm3Id string = vm[2].id
