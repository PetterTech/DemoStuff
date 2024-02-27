targetScope = 'resourceGroup'

param LocalVnetID string
param RemoteVnetID string
param useRemoteGateways bool

var LocalVnetNameAsArray = split(LocalVnetID,'/')
var LocalVnetName = last(LocalVnetNameAsArray)

var RemoteVnetNameAsArray = split(RemoteVnetID,'/')
var RemoteVnetName = last(RemoteVnetNameAsArray)

resource peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${LocalVnetName}/peer-${RemoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: useRemoteGateways
    remoteVirtualNetwork: {
      id: RemoteVnetID
    }
  }
}
