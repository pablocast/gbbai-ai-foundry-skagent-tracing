param accountName string
param location string
param projectName string
param projectDescription string
param displayName string
param aiSearchName string
param aiSearchServiceResourceGroupName string
param aiSearchServiceSubscriptionId string
param cosmosDBName string
param cosmosDBSubscriptionId string
param cosmosDBResourceGroupName string
param azureStorageName string
param azureStorageSubscriptionId string
param azureStorageResourceGroupName string

// AI Project
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: '${accountName}/${projectName}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: displayName
  }
}

// Cosmos DB Connection
resource cosmosConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  parent: aiProject
  name: cosmosDBName
  properties: {
    category: 'CosmosDB'
    target: reference(resourceId(cosmosDBSubscriptionId, cosmosDBResourceGroupName, 'Microsoft.DocumentDB/databaseAccounts', cosmosDBName), '2024-12-01-preview').documentEndpoint
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: resourceId(cosmosDBSubscriptionId, cosmosDBResourceGroupName, 'Microsoft.DocumentDB/databaseAccounts', cosmosDBName)
      location: reference(resourceId(cosmosDBSubscriptionId, cosmosDBResourceGroupName, 'Microsoft.DocumentDB/databaseAccounts', cosmosDBName), '2024-12-01-preview', 'full').location
    }
  }
}

// Storage Connection
resource storageConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  parent: aiProject
  name: azureStorageName
  properties: {
    category: 'AzureStorageAccount'
    target: reference(resourceId(azureStorageSubscriptionId, azureStorageResourceGroupName, 'Microsoft.Storage/storageAccounts', azureStorageName), '2023-05-01').primaryEndpoints.blob
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: resourceId(azureStorageSubscriptionId, azureStorageResourceGroupName, 'Microsoft.Storage/storageAccounts', azureStorageName)
      location: reference(resourceId(azureStorageSubscriptionId, azureStorageResourceGroupName, 'Microsoft.Storage/storageAccounts', azureStorageName), '2023-05-01', 'full').location
    }
  }
}

// AI Search Connection
resource searchConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' = {
  parent: aiProject
  name: aiSearchName
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${aiSearchName}.search.windows.net'
    authType: 'AAD'
    metadata: {
      ApiType: 'Azure'
      ResourceId: resourceId(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName, 'Microsoft.Search/searchServices', aiSearchName)
      location: reference(resourceId(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName, 'Microsoft.Search/searchServices', aiSearchName), '2024-06-01-preview', 'full').location
    }
  }
}

// Helper function to format workspace ID as GUID - using unique string for now
var projectWorkspaceId = uniqueString(aiProject.id)
var guidValue = '${projectWorkspaceId}0000000000000000000000000000'
var part1 = substring(guidValue, 0, 8)
var part2 = substring(guidValue, 8, 4)
var part3 = substring(guidValue, 12, 4)
var part4 = substring(guidValue, 16, 4)
var part5 = substring(guidValue, 20, 12)
var projectWorkspaceIdGuid = '${part1}-${part2}-${part3}-${part4}-${part5}'

// Outputs
output projectName string = projectName
output projectId string = aiProject.id
output projectPrincipalId string = aiProject.identity.principalId
output projectWorkspaceId string = projectWorkspaceId
output projectWorkspaceIdGuid string = projectWorkspaceIdGuid
output cosmosDBConnection string = cosmosDBName
output azureStorageConnection string = azureStorageName
output aiSearchConnection string = aiSearchName
output projectEndpoint string = 'https://${accountName}.services.ai.azure.com/api/projects/${projectName}'
