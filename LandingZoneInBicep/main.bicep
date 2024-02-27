targetScope = 'subscription'

param TargetLocation string // = 'swedencentral'
param AddressSpace string // = '10.100.3.0/24'
param HubVnetID string 

var HubVnetIDAsArray = split(HubVnetID,'/')
//var HubVnetName = last(HubVnetIDAsArray)

var HubResourcegroupID = take(HubVnetIDAsArray,5)
var HubResourceGroupName = last(HubResourcegroupID)

resource ResourceGroupNetwork 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-DEMOLandingZone1'
  location: TargetLocation
}

module vNetLandingZoneModule 'vnetLandingZone.bicep' = {
  name: 'vnetLandingZoneModule'
  scope: ResourceGroupNetwork
  params: {
    Location: TargetLocation
    AddressSpace: AddressSpace
  }
} 

module PeerLandingZoneWithHub 'peering.bicep' = {
  scope: ResourceGroupNetwork
  name: 'PeerLandingZoneWithHub'
  params: {
    LocalVnetID: vNetLandingZoneModule.outputs.vnetLandingZoneID
    RemoteVnetID: HubVnetID
    useRemoteGateways: true
  }
}

module PeerHubWithLandingZone 'peering.bicep' = {
  scope: resourceGroup(HubResourceGroupName)
  name: 'PeerHubWithLandingZone'
  params: {
    LocalVnetID: HubVnetID
    RemoteVnetID: vNetLandingZoneModule.outputs.vnetLandingZoneID
    useRemoteGateways: false
  }
}

output vnetID string = vNetLandingZoneModule.outputs.vnetLandingZoneID
