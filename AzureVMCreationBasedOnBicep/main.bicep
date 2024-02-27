param now string = utcNow('yyyyMMdd')
param adminUsername string
@secure()
param adminPassword string
param vmName string
param location string
param deployingUser string
param vmSize string
param imageOffer string
param imageSku string
param imageVersion string
param imagePublisher string
param subnetID string

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nic-${vmName}'
  location: location
  tags: {
    DeployedBy: deployingUser
    DeploymentTime: now
  }
  properties: {
    ipConfigurations: [
      {
      name: 'ipconfig1'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: subnetID
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: location
    tags: {
      DeployedBy: deployingUser
      DeploymentDate: now
    }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      imageReference: {
        offer: imageOffer
        sku: imageSku
        version: imageVersion
        publisher: imagePublisher

      }
    }
  }
}
