param clusterName string
param location string
param clusterAdminPrincipalId string

// AKS Automatic: system node pools are managed by Azure and must NOT be declared here —
// an explicit agentPoolProfiles system pool makes cluster creation fail.
// OIDC issuer and workload identity are on by default for Automatic, but are kept explicit
// because the identity module depends on the issuer URL output.
resource aks 'Microsoft.ContainerService/managedClusters@2026-02-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Automatic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
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
