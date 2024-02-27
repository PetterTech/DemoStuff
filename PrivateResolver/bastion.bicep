param location string
param HubSubnetID string

resource BastionpublicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: 'pip-Bastion'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}


resource Bastion 'Microsoft.Network/bastionHosts@2021-08-01' = {
  name: 'Bastion'
  location: location
  properties: {
    disableCopyPaste: false
    ipConfigurations: [
      {
        name: 'BastionIPConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: BastionpublicIPAddress.id
          }
          subnet: {
            id: HubSubnetID
          }
        }
      }
    ]
  }
}
