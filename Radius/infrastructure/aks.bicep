param clusterName string
param location string
param clusterAdminPrincipalId string

resource aks 'Microsoft.ContainerService/managedClusters@2024-09-02-preview' = {
  name: clusterName
  location: location
  sku: {
    name: 'Automatic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'systempool'
        mode: 'System'
        count: 3
        vmSize: 'Standard_D4ds_v5'
      }
    ]
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    safeguardsProfile: {
      level: 'Warning'
    }
  }
}

// Azure Kubernetes Service RBAC Cluster Admin
var aksRbacClusterAdminRoleId = 'b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

resource aksRbacClusterAdminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: aksRbacClusterAdminRoleId
}

resource clusterAdminRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aks.id, clusterAdminPrincipalId, aksRbacClusterAdminRole.id)
  scope: aks
  properties: {
    principalId: clusterAdminPrincipalId
    principalType: 'User'
    roleDefinitionId: aksRbacClusterAdminRole.id
  }
}

output clusterName string = aks.name
output oidcIssuerUrl string = aks.properties.oidcIssuerProfile.issuerURL
