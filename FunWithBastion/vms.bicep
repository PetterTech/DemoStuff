param location string
param spoke1SubnetID string
param spoke2SubnetID string
param AdminUsername string
@secure()
param AdminPassword string

resource Spoke1NIC 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'spoke1vm01-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spoke1SubnetID
          }
        }
      }
    ]
  }
}


resource spoke1VM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'spoke1vm01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'spoke1vm01'
      adminUsername: AdminUsername
      adminPassword: AdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'spoke1vm01-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Spoke1NIC.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource Spoke2NIC 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'spoke2vm01-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: spoke2SubnetID
          }
        }
      }
    ]
  }
}

resource Spoke2vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: 'spoke2vm01'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'spoke2vm01'
      adminUsername: AdminUsername
      adminPassword: AdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'spoke2vm01-osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: Spoke2NIC.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}
