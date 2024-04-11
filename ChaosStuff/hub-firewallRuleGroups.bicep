param firewallPolicyName string
param spoke1ipgroupID string
param spoke2ipgroupID string

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' existing = {
  name: firewallPolicyName
}

resource coreRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: 'coreRuleGroup'
  parent: firewallPolicy
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        action: {
          type: 'Allow'
        }
        name: 'Allow HTTPS out'
        priority: 1000
        rules: [
          {
            ruleType: 'ApplicationRule'
            targetFqdns: [
              '*'
            ]
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceIpGroups: [
              spoke1ipgroupID
              spoke2ipgroupID
            ]
          }
        ]
      }
    ]
  }
}
