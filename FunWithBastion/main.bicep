targetScope = 'resourceGroup'

param location string = 'norwayeast'
param AdminUsername string = 'PetterTech'
@secure()
param AdminPassword string

module BastionvNets 'vnets.bicep' = {
  name: 'BastionvNets'
  params: {
    location: location
  }
}

module BastionVMs 'vms.bicep' = {
  name: 'BastionVMs'
  params: {
    AdminPassword: AdminPassword
    AdminUsername: AdminUsername 
    location: location
    spoke1SubnetID: BastionvNets.outputs.Spoke1SubnetID
    spoke2SubnetID: BastionvNets.outputs.Spoke2SubnetID
  }
}

module Peerings 'vnetPeering.bicep' = {
  name: 'Peering'
  params: {
    HubID: BastionvNets.outputs.HubID
    Spoke1ID: BastionvNets.outputs.Spoke1ID
    Spoke2ID: BastionvNets.outputs.Spoke2ID
  }
}

module BastionHost 'bastion.bicep' = {
  name: 'BastionHost'
  params: {
    HubSubnetID: BastionvNets.outputs.HubBastionSubnetID
    location: location
  }
}
