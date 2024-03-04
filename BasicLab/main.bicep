targetScope = 'resourceGroup'

param location string = 'northeurope'

module natGateway 'natGateway.bicep' = {
  name: 'natGateway'
  params: {
    location: location
  }
}

module vnet 'vnet.bicep' = {
  name: 'vnet'
  params: {
    location: location
    natGatewayId: natGateway.outputs.natGatewayId
  }
}

module bastion 'bastion.bicep' = {
  name: 'bastion'
  params: {
    bastionSubnetId: vnet.outputs.bastionSubnetId
    location: location
  }
}
