param myLocation string
param subnetId string
param username string

@secure()
param password string

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'labvmnic'
  location: myLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'labvm'
  location: myLocation
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D4_v3'
    }
    osProfile: {
      computerName: 'labvm'
      adminUsername: username
      adminPassword: password
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2022-Datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
