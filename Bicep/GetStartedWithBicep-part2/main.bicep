@secure()
param password string
param username string
var myLocation = 'northeurope'

module vnet 'vnet.bicep' = {
  params: {
    myLocation: myLocation
  }
}

module vm 'vm.bicep' = {
  params: {
    myLocation: myLocation
    password: password
    subnetId: vnet.outputs.subnetid
    username: username
  }
}
