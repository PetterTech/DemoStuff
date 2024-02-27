param HubID string
param Spoke1ID string
param Spoke2ID string

var HubIDAsArray = split(HubID,'/')
var HubName = last(HubIDAsArray)

var Spoke1AsArray = split(Spoke1ID,'/')
var Spoke1Name = last(Spoke1AsArray)

var Spoke2AsArray = split(Spoke2ID,'/')
var Spoke2Name = last(Spoke2AsArray)

resource HubToSpoke1Peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${HubName}/peer-${Spoke1Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: Spoke1ID
    }
  }
}

resource HubToSpoke2Peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${HubName}/peer-${Spoke2Name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: Spoke2ID
    }
  }
}

resource Spoke1ToHubPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${Spoke1Name}/peer-${HubName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: HubID
    }
  }
}

resource Spoke2ToHubPeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${Spoke2Name}/peer-${HubName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: HubID
    }
  }
}
