param location string
param lbName string
param lbSkuName string
param lbPublicIpAddressName string
param lbFrontEndName string
param lbBackendPoolName string
param lbProbeName string



resource lbPublicIPAddress 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: lbPublicIpAddressName
  location: location
  sku: {
    name: lbSkuName
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource lb 'Microsoft.Network/loadBalancers@2021-08-01' = {
  name: lbName
  location: location
  sku: {
    name: lbSkuName
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: lbFrontEndName
        properties: {
          publicIPAddress: {
            id: lbPublicIPAddress.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: lbBackendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'myHTTPRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, lbFrontEndName)
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, lbBackendPoolName)
          }
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 15
          protocol: 'Tcp'
          enableTcpReset: true
          loadDistribution: 'Default'
          disableOutboundSnat: true
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, lbProbeName)
          }
        }
      }
    ]
    probes: [
      {
        name: lbProbeName
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    outboundRules: [
    ]
  }
}

output lbPublicIpAddressId string = lbPublicIPAddress.properties.ipAddress
