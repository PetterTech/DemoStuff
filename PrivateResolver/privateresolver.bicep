param location string
param hubvnetID string
param inboundSubnetID string
param outboundSubnetID string

resource privateResolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: 'privateResolver'
  location: location
  properties: {
    virtualNetwork: {
      id: hubvnetID
    }
  }
}

resource inboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  name: 'inboundEndpoint'
  location: location
  parent: privateResolver
  properties: {
    ipConfigurations: [
      {
        privateIpAddress: '10.200.0.70'
        privateIpAllocationMethod: 'Static'
        subnet: {
          id: inboundSubnetID
        }
      }
    ]
  }
}

resource outboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  name: 'outboundEndpoint'
  location: location
  parent: privateResolver
  properties: {
    subnet: {
      id: outboundSubnetID
    }
  }
}

resource labzoneRuleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: 'labzoneRuleset'
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outboundEndpoint.id
      }
    ]
  }
}

resource labzoneForwarding 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  name: 'labzoneForwarding'
  parent: labzoneRuleset
  properties: {
    domainName: 'labzone.local.'
    targetDnsServers: [
       {
        ipAddress: '10.100.0.5'
        port: 53
       }
    ]
  }
}

resource rulesetVnetLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  name: 'rulesetVnetLink'
  parent: labzoneRuleset
  properties: {
    virtualNetwork: {
      id: hubvnetID
    }
  }
}

resource spokevnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'Spoke'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.201.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.201.0.0/26'
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        '10.200.0.70'
      ]
    }
  }
}
