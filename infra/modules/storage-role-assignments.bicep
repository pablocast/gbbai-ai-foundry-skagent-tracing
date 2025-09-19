param azureStorageName string
param projectPrincipalId string
param searchServicePrincipalId string
param principalId string
param managedIdentityPrincipalId string


// Reference to existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: azureStorageName
}

// Storage Blob Data Contributor role assignment
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(projectPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', storageAccount.id)
  scope: storageAccount
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'ServicePrincipal'
  }
}

// Storage Role for Search Service
resource storageRoleSearchService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(searchServicePrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', storageAccount.id)
  properties: {
    principalId: searchServicePrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'ServicePrincipal'
  }
}


// Storage Blob Data Reader role for User
resource storageRoleReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(principalId, '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1', storageAccount.id)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalType: 'User'
  }
}

// Storage Blob Data Contributor role for User
resource storageRoleContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(principalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', storageAccount.id)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'User'
  }
}


// Storage Blob Delegator role for project (needed for user delegation SAS)
resource storageDelegatorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(projectPrincipalId, 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a', storageAccount.id)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a')
    principalType: 'ServicePrincipal'
  }
}


// Storage Blob Data Reader role for Managed Identity
resource storageRoleReaderManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(subscription().id, '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1', storageAccount.id, managedIdentityPrincipalId)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Data Contributor role for Managed Identity
resource storageRoleContributorManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(subscription().id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', storageAccount.id, managedIdentityPrincipalId)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalType: 'ServicePrincipal'
  }
}

// Storage Blob Delegator role for Managed Identity
resource storageRoleDelegatorManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(subscription().id, 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a', storageAccount.id, managedIdentityPrincipalId)
  properties: {
    principalId: managedIdentityPrincipalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'db58b8e5-c6ad-4a2a-8342-4190687cbf4a')
    principalType: 'ServicePrincipal'
  }
}
