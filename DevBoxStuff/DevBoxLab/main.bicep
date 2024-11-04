targetScope = 'resourceGroup'

param location string = 'swedencentral'
param devCenterName string = 'devCenterName'
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

module bastion 'bastion.bicep' = {
  name: 'bastion'
  params: {
    bastionSubnetId: vnet.outputs.bastionSubnetId
    location: location
  }
}

module devBox 'devbox.bicep' = {
  name: 'devCenter'
  params: {
    location: location
    devCenterName: devCenterName
    devPrincipalId: devPrincipalId
  }
}
