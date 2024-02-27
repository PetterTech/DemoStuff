param location string

resource OnPremVM 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: 'OnPremVM'
}

resource createDNSConditionalForwarder 'Microsoft.Compute/virtualMachines/runCommands@2023-09-01' = {
  name: 'createDNSConditionalForwarder'
  location: location
  parent: OnPremVM
  properties: {
    source: {
      script: 'Add-DnsServerConditionalForwarderZone -Name "file.${environment().suffixes.storage}" -MasterServers 10.200.0.70'
    }
  }
}
