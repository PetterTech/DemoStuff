@description('Project name used for resource naming')
param projectName string = 'crossplane'

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

module crossplaneIdentity 'crossplaneIdentity.bicep' = {
  params: {
    identityName: 'id-${projectName}-azure-provider'
    location: location
    oidcIssuerUrl: aks.outputs.oidcIssuerUrl
  }
}

output clusterName string = aks.outputs.clusterName
output crossplaneIdentityClientId string = crossplaneIdentity.outputs.clientId
