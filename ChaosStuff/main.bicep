targetScope = 'resourceGroup'

param location string = 'swedencentral'
param localAdminUsername string = 'pettertech'
@secure()
param localAdminPassword string = 'LongAndStrongP@ssw0rd1234'
param storageAccountName string = 'pt${uniqueString(resourceGroup().id)}'
param hubiprange string = '10.200.0.0/24'
param firewallsubnetrange string = '10.200.0.0/26'
param dnsinboundrange string = '10.200.0.64/26'
param dnsoutboundrange string = '10.200.0.128/26'
param bastionrange string = '10.200.0.192/26'
param spoke1iprange string = '10.100.0.0/24'
param spoke2iprange string = '10.201.0.0/24'

var spoke1defaultsubnetrangearray = [
  (split(spoke1iprange,'/')[0])
  '26'
]
var spoke1defaultsubnetrange = join(spoke1defaultsubnetrangearray,'/')
var spoke2defaultsubnetrangearray = [
  (split(spoke2iprange,'/')[0])
  '26'  
]
var spoke2defaultsubnetrange = join(spoke2defaultsubnetrangearray,'/')

module hubvnet 'hub-vnet.bicep' = {
  name: 'hubvnet'
  params: {
    bastionrange: bastionrange
    dnsinboundrange: dnsinboundrange
    dnsoutboundrange: dnsoutboundrange
    firewallsubnetrange: firewallsubnetrange
    hubiprange: hubiprange
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
    spoke1iprange: spoke1iprange
    spoke2iprange: spoke2iprange
  }
  dependsOn: [
    hubvnet
  ]
}

module hubazurefirewallrulegroups 'hub-firewallRuleGroups.bicep' = {
  name: 'hubazurefirewallrulegroups'
  params: {
    firewallPolicyName: hubazurefirewall.outputs.azureFirewallPolicyName
    spoke1ipgroupID: hubazurefirewall.outputs.spoke1ipgroupID
    spoke2ipgroupID: hubazurefirewall.outputs.spoke2ipgroupID
  }
  dependsOn: [
    hubazurefirewall
  ]
}

module spoke1vnet 'spoke1-vnet.bicep' = {
  name: 'spoke1vnet'
  params: {
    location: location
    azureFirewallPrivateIP: hubazurefirewall.outputs.azureFirewallPrivateIP
    spoke1defaultsubnetrange: spoke1defaultsubnetrange
    spoke1iprange: spoke1iprange
  }
}

module spoke2vnet 'spoke2-vnet.bicep' = {
  name: 'spoke2vnet'
  params: {
    location: location
    azureFirewallPrivateIP: hubazurefirewall.outputs.azureFirewallPrivateIP
    spoke2defaultsubnetrange: spoke2defaultsubnetrange
    spoke2iprange: spoke2iprange
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

