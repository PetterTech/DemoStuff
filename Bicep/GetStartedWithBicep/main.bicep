resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'labvnet'
   location: 'northeurope'
    properties: {
       addressSpace: {
         addressPrefixes: [
          '10.13.37.0/24'
         ]
       }
        subnets: [
           {
             name: 'labsubnet'
              properties: {
                 addressPrefix: '10.13.37.0/24'
              }
           }
        ]
    }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: 'labvmnic'
   location: 'northeurope'
    properties: {
       ipConfigurations: [
         {
           name: 'ipconfig1'
            properties: {
               subnet: {
                 id: vnet.properties.subnets[0].id
               }
            }
         }
       ]
    }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'labvm'
  location: 'northeurope'
  properties: {
     hardwareProfile: {
       vmSize: 'Standard_D4_v3'
     }
     osProfile: {
       computerName: 'labvm'
       adminUsername: 'pettertech'
       adminPassword: 'LongAndStrongPassword!'
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
