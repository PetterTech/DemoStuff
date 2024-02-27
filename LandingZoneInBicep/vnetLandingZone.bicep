targetScope = 'resourceGroup'

param Location string 
param AddressSpace string

resource vnetLandingZone 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet-DEMOLandingZone1'
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        AddressSpace
      ]
    }
    subnets: [
      {
        name: 'snet-DEMOLandingZone1'
        properties: {
          addressPrefix: AddressSpace
        }
      }
    ]
  }
}

output vnetLandingZoneID string = vnetLandingZone.id
