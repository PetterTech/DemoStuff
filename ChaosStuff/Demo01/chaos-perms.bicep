param id1 string
param id2 string

var vmContributorRoleId = '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'

resource vmContributorRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: vmContributorRoleId
}

resource roleAssignment1 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().name, vmContributorRoleId, id1)
  properties: {
    principalId: id1
    principalType: 'ServicePrincipal'
    roleDefinitionId: vmContributorRole.id
  }
}

resource roleAssignment2 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().name, vmContributorRoleId, id2)
  properties: {
    principalId: id2
    principalType: 'ServicePrincipal'
    roleDefinitionId: vmContributorRole.id
  }
}
