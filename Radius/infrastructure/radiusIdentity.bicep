param identityName string
param location string
param oidcIssuerUrl string
param serviceAccountNamespace string = 'radius-system'
param serviceAccountName string = 'ucp'

// Managed identity for the Radius UCP (Universal Control Plane) component
resource radiusIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Federated credential linking AKS OIDC to the Radius UCP service account
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: radiusIdentity
  name: 'radius-azure-provider'
  properties: {
    issuer: oidcIssuerUrl
    subject: 'system:serviceaccount:${serviceAccountNamespace}:${serviceAccountName}'
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

// Contributor role on the resource group
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: contributorRoleId
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, radiusIdentity.id, contributorRoleDefinition.id)
  properties: {
    principalId: radiusIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinition.id
  }
}

output clientId string = radiusIdentity.properties.clientId
