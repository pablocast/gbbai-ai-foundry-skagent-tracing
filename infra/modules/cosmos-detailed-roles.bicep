@description('Name of the AI Search resource')
param cosmosAccountName string

@description('Project name')
param projectPrincipalId string

param projectWorkspaceId string

var userThreadName = '${projectWorkspaceId}-thread-message-store'
var systemThreadName = '${projectWorkspaceId}-system-thread-message-store'
var entityStoreName = '${projectWorkspaceId}-agent-entity-store'

// Reference to existing Cosmos DB account
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosAccountName
  scope: resourceGroup()
}

// Create the enterprise_memory database
resource enterpriseMemoryDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-12-01-preview' = {
  parent: cosmosAccount
  name: 'enterprise_memory'
  properties: {
    resource: {
      id: 'enterprise_memory'
    }
  }
}

// Create User Thread Container
resource userThreadContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = {
  parent: enterpriseMemoryDatabase
  name: userThreadName
  properties: {
    resource: {
      id: userThreadName
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
    options: {
      throughput: 400
    }
  }
}

// Create System Thread Container
resource systemThreadContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = {
  parent: enterpriseMemoryDatabase
  name: systemThreadName
  properties: {
    resource: {
      id: systemThreadName
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
    options: {
      throughput: 400
    }
  }
}

// Create Entity Store Container
resource entityStoreContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = {
  parent: enterpriseMemoryDatabase
  name: entityStoreName
  properties: {
    resource: {
      id: entityStoreName
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
    options: {
      throughput: 400
    }
  }
}

var roleDefinitionId = resourceId('Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions', cosmosAccountName, '00000000-0000-0000-0000-000000000002')
var scopeSystemContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${systemThreadName}'
var scopeUserContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${userThreadName}'
var scopeEntityContainer = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosAccountName}/dbs/enterprise_memory/colls/${entityStoreName}'

// User Thread Container Role Assignment
resource userThreadRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(projectWorkspaceId, userThreadName, roleDefinitionId, projectPrincipalId)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeUserContainer
  }
  dependsOn: [
    userThreadContainer
  ]
}

// System Thread Container Role Assignment
resource systemThreadRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(projectWorkspaceId, systemThreadName, roleDefinitionId, projectPrincipalId)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeSystemContainer
  }
  dependsOn: [
    systemThreadContainer
  ]
}

// Entity Store Container Role Assignment
resource entityStoreRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-05-15' = {
  parent: cosmosAccount
  name: guid(projectWorkspaceId, entityStoreName, roleDefinitionId, projectPrincipalId)
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: scopeEntityContainer
  }
  dependsOn: [
    entityStoreContainer
  ]
}

resource assignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: guid(projectWorkspaceId, cosmosAccount.name, roleDefinitionId, projectPrincipalId)
  parent: cosmosAccount
  properties: {
    principalId: projectPrincipalId
    roleDefinitionId: roleDefinitionId
    scope: cosmosAccount.id
  }
}
