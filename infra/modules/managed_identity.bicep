// ========== Managed Identity ========== //
targetScope = 'resourceGroup'

@minLength(3)
@maxLength(40)
@description('Solution Name')
param name string

@description('Solution Location')
param location string

@description('Name')
param miName string = '${ name }-managed-identity'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: miName
  location: location
  tags: {
    app: name
    location: location
  }
}

@description('This is the built-in owner role. See https://docs.microsoft.com/azure/role-based-access-control/built-in-roles#owner')
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: resourceGroup()
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, managedIdentity.id, ownerRoleDefinition.id)
  properties: {
    principalId: managedIdentity.properties.principalId
    roleDefinitionId:  ownerRoleDefinition.id
    principalType: 'ServicePrincipal' 
  }
}

output managedIdentityOutput object = {
  id: managedIdentity.id
  objectId: managedIdentity.properties.principalId
  name: miName
  clientId: managedIdentity.properties.clientId
}
