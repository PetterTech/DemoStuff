targetScope = 'resourceGroup'

param location string = 'swedencentral'
param projectName string
param devPrincipalId string

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
/*
module bastion 'bastion.bicep' = {
  name: 'bastion'
  params: {
    bastionSubnetId: vnet.outputs.bastionSubnetId
    location: location
  }
}
*/
module devBox 'devbox.bicep' = {
  name: 'devCenter'
  params: {
    location: location
    projectName: projectName
    devPrincipalId: devPrincipalId
    vmSubnetId: vnet.outputs.vmSubnetId
  }
}
