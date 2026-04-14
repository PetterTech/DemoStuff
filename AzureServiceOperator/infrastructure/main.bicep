@description('Project name used for resource naming')
param projectName string = 'aso'

@description('Azure region for all resources')
param location string = 'swedencentral'

@description('Principal ID of the user to assign AKS RBAC Cluster Admin')
param clusterAdminPrincipalId string

module aks 'aks.bicep' = {
  params: {
    clusterName: 'aks-${projectName}'
    location: location
    clusterAdminPrincipalId: clusterAdminPrincipalId
  }
}

module asoIdentity 'asoIdentity.bicep' = {
  params: {
    identityName: 'id-${projectName}-operator'
    location: location
    oidcIssuerUrl: aks.outputs.oidcIssuerUrl
  }
}

output clusterName string = aks.outputs.clusterName
output asoIdentityClientId string = asoIdentity.outputs.clientId
