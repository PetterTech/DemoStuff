targetScope = 'resourceGroup'

param location string = 'swedencentral'
param localAdminUsername string = 'pettertech'
@secure()
param localAdminPassword string = 'LongAndStrongP@ssw0rd1234'
param storageAccountName string = 'pt${uniqueString(resourceGroup().id)}'

module hubvnet 'hub-vnet.bicep' = {
  name: 'hubvnet'
  params: {
    location: location
  }
}

module hubbastion 'hub-bastion.bicep' = {
  name: 'hubbastion'
  params: {
    BastionSubnetID: hubvnet.outputs.bastionSubnetID
    location: location
  }
  dependsOn: [
    hubvnet
  ]
}

module hubprivateresolver 'hub-privateresolver.bicep' = {
  name: 'hubprivateresolver'
  params: {
    location: location
    hubvnetID: hubvnet.outputs.vnetID
    inboundSubnetID: hubvnet.outputs.inboundSubnetID
    outboundSubnetID: hubvnet.outputs.outboundSubnetID
  }
  dependsOn: [
    hubvnet
  ]
}

module hubazurefirewall 'hub-firewall.bicep' = {
  name: 'hubazurefirewall'
  params: {
    location: location
    firewallsubnetID: hubvnet.outputs.firewallSubnetID
  }
  dependsOn: [
    hubvnet
  ]
}

module spoke1vnet 'spoke1-vnet.bicep' = {
  name: 'spoke1vnet'
  params: {
    location: location
    azureFirewallPrivateIP: hubazurefirewall.outputs.azureFirewallPrivateIP
  }
}

module spoke2vnet 'spoke2-vnet.bicep' = {
  name: 'spoke2vnet'
  params: {
    location: location
    azureFirewallPrivateIP: hubazurefirewall.outputs.azureFirewallPrivateIP
  }
}

module spoke1VMs 'spoke1-VMs.bicep' = {
  name: 'spoke1VMs'
  params: {
    location: location
    localAdminUsername: localAdminUsername
    localAdminPassword: localAdminPassword
    spoke1subnetID: spoke1vnet.outputs.spoke1subnetID
  }
  dependsOn: [
    spoke1vnet
  ]
}

module spoke2VMs 'spoke2-VMs.bicep' = {
  name: 'spoke2VMs'
  params: {
    location: location
    localAdminUsername: localAdminUsername
    localAdminPassword: localAdminPassword
    spoke2subnetID: spoke2vnet.outputs.spoke2subnetID
  }
  dependsOn: [
    spoke2vnet
  ]
}

module vnetpeering 'vnetPeering.bicep' = {
  name: 'vnetpeering'
  params: {
    HubID: hubvnet.outputs.vnetID
    Spoke1ID: spoke1vnet.outputs.spoke1vnetID
    Spoke2ID: spoke2vnet.outputs.spoke2vnetID
  }
  dependsOn: [
    hubvnet
    spoke1vnet
    spoke2vnet
  ]
}

module spoke2storage 'spoke2-storage.bicep' = {
  name: 'spoke2storage'
  params: {
    location: location
    hubVnetID: hubvnet.outputs.vnetID
    spoke2VnetID: spoke2vnet.outputs.spoke2vnetID
    spoke2SubnetID: spoke2vnet.outputs.spoke2subnetID
    storageAccountName: storageAccountName
  }
  dependsOn: [
    spoke2vnet
  ]
}

