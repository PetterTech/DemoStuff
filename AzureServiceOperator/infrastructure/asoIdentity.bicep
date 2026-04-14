param identityName string
param location string
param oidcIssuerUrl string

// ASO v2 operator service account — namespace and name are fixed by the Helm chart
param serviceAccountNamespace string = 'azureserviceoperator-system'
param serviceAccountName string = 'azureserviceoperator-default'

// Managed identity for the ASO operator
resource asoIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

// Federated credential linking AKS OIDC to the ASO operator service account
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: asoIdentity
  name: 'aso-operator'
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
  name: guid(resourceGroup().id, asoIdentity.id, contributorRoleDefinition.id)
  properties: {
    principalId: asoIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDefinition.id
  }
}

output clientId string = asoIdentity.properties.clientId
