param location string
param projectName string
param adminUsername string
@secure()
param adminPassword string
param vmSize string = 'Standard_D2ads_v5'
param OSVersion string = '2022-datacenter-azure-edition'
param securityType string = 'TrustedLaunch'

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var lbName = 'lbe-${projectName}'
var lbSkuName = 'Standard'
var lbPublicIpAddressName = 'pip-lbe${projectName}'
var lbFrontEndName = 'lbFrontEnd'
var lbBackendPoolName = 'lbBackEndPool'
var lbProbeName = 'lbHealthProbe'
var nsgName = 'nsg-${projectName}'
var vNetName = 'vnet-${projectName}'
var vNetAddressPrefix = '10.13.0.0/16'
var vNetSubnetName = 'BackendSubnet'
var vNetSubnetAddressPrefix = '10.13.37.0/24'
var bastionName = 'bas-${projectName}'
var bastionSubnetName = 'AzureBastionSubnet'
var basSkuName = 'Standard'
var vNetBastionSubnetAddressPrefix = '10.13.38.0/24'
var bastionPublicIPAddressName = 'pip-bas${projectName}'
var vmStorageAccountType = 'Premium_LRS'
var natGatewayName = 'ngw-${projectName}'
var natGatewayPublicIPAddressName = 'pip-ngw${projectName}'

module natgw 'natgw.bicep' = {
  name: 'NATGateway'
  params: {
    location: location
    natGatewayPublicIPAddressName: natGatewayPublicIPAddressName
    natGatewayName: natGatewayName
  }
}

module vnet 'vnet.bicep' = {
  name: 'vNet'
  params: {
    location: location
    nsgName: nsgName
    vNetName: vNetName
    vNetAddressPrefix: vNetAddressPrefix
    vNetSubnetName: vNetSubnetName
    vNetSubnetAddressPrefix: vNetSubnetAddressPrefix
    bastionSubnetName: bastionSubnetName
    vNetBastionSubnetAddressPrefix: vNetBastionSubnetAddressPrefix
    natGatewayId: natgw.outputs.natGatewayId
  }
}

module lbe 'lbe.bicep' = {
  name: 'LoadBalancer'
  params: {
    location: location
    lbName: lbName
    lbSkuName: lbSkuName
    lbPublicIpAddressName: lbPublicIpAddressName
    lbFrontEndName: lbFrontEndName
    lbBackendPoolName: lbBackendPoolName
    lbProbeName: lbProbeName
  }
}

module bastion 'bastion.bicep' = {
  name: 'Bastion'
  params: {
    location: location
    bastionPublicIPAddressName: bastionPublicIPAddressName
    basSkuName: basSkuName
    bastionSubnetID: vnet.outputs.bastionSubnetId
    bastionName: bastionName
  }
}

module vms 'vms.bicep' = {
  name: 'VMs'
  params: {
    location: location
    projectName: projectName
    vmSize: vmSize
    OSVersion: OSVersion
    adminPassword: adminPassword
    adminUsername: adminUsername
    securityProfileJson: securityProfileJson
    vmsubnetId: vnet.outputs.vmSubnetId
    vmStorageAccountType: vmStorageAccountType
    nsgId: vnet.outputs.nsgId
    lbName: lbName
    lbBackendPoolName: lbBackendPoolName
  }
}
