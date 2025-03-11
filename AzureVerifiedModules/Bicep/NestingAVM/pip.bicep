param name string

module publicIpAddress 'br/public:avm/res/network/public-ip-address:0.8.0' = {
  name: 'publicIpAddressDeployment'
  params: {
    name: name
    ddosSettings: {
      protectionMode: 'Enabled'
    }
  }
}
