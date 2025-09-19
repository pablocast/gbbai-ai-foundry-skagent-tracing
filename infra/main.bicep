targetScope = 'resourceGroup'

// Parameters
@description('The Azure region where your AI Foundry resource and project will be created.')
@allowed([
  'australiaeast'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'japaneast'
  'koreacentral'
  'norwayeast'
  'northcentralus'
  'polandcentral'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'uaenorth'
  'uksouth'
  'westus'
  'westus2'
  'westus3'
  'westeurope'
  'southeastasia'
])
param location string 
param locationOpenai string 

param principalId string = subscription().tenantId

@description('The name of the Azure AI Foundry resource.')
@maxLength(9)
param aiServices string = 'foundry'

@description('Name for your project resource.')
param firstProjectName string = 'project'

@description('This project will be a sub-resource of your account')
param projectDescription string = 'some description'

@description('The display name of the project')
param displayName string = 'project'

@description('Array of models to deploy')
param models array = [
  {
    name: 'gpt-4o'
    format: 'OpenAI'
    version: '2024-05-13'
    skuName: 'GlobalStandard'
    capacity: 1
  }
  {
    name: 'gpt-4.1'
    format: 'OpenAI'
    version: '2025-04-14'
    skuName: 'GlobalStandard'
    capacity: 1
  }
  {
    name: 'text-embedding-3-large'
    format: 'OpenAI'
    version: '1'
    skuName: 'Standard'
    capacity: 1
  }
]

@description('The AI Search Service full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiSearchResourceId string = ''

@description('The AI Storage Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param azureStorageAccountResourceId string = ''

@description('The Cosmos DB Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param azureCosmosDBAccountResourceId string = ''

@description('The AI Services Account full ARM Resource ID. This is an optional field, and if not provided, the resource will be created.')
param aiServicesResourceId string = ''

param projectCapHost string = 'caphostproj'
param accountCapHost string = 'caphostacc'
param deploymentTimestamp string = utcNow('yyyyMMddHHmmss')

// Derived variables
var uniqueSuffix = substring(uniqueString('${resourceGroup().id}-${deploymentTimestamp}'), 0, 4)
var accountName = toLower('${aiServices}${uniqueSuffix}')
var projectName = toLower('${firstProjectName}${uniqueSuffix}')
var cosmosDBName = toLower('${uniqueSuffix}cosmosdb')
var aiSearchName = toLower('${uniqueSuffix}search')
var azureStorageName = toLower('${uniqueSuffix}storage')
var cogServicesName = toLower('${accountName}cogservices')
var logAnalyticsName = toLower('${accountName}loganalytics')
var insightsName = toLower('${accountName}insights')

var storagePassedIn = !empty(azureStorageAccountResourceId)
var searchPassedIn = !empty(aiSearchResourceId)
var cosmosPassedIn = !empty(azureCosmosDBAccountResourceId)
var aiServicePassedIn = !empty(aiServicesResourceId)

var acsParts = split(aiSearchResourceId, '/')
var aiSearchServiceSubscriptionId = searchPassedIn ? acsParts[2] : subscription().subscriptionId
var aiSearchServiceResourceGroupName = searchPassedIn ? acsParts[4] : resourceGroup().name

var cosmosParts = split(azureCosmosDBAccountResourceId, '/')
var cosmosDBSubscriptionId = cosmosPassedIn ? cosmosParts[2] : subscription().subscriptionId
var cosmosDBResourceGroupName = cosmosPassedIn ? cosmosParts[4] : resourceGroup().name

var storageParts = split(azureStorageAccountResourceId, '/')
var azureStorageSubscriptionId = storagePassedIn ? storageParts[2] : subscription().subscriptionId
var azureStorageResourceGroupName = storagePassedIn ? storageParts[4] : resourceGroup().name
var docsContainerName = 'documents'
var artifactsContainerName = 'artifacts'

var aiServiceAccountParts = split(aiServicesResourceId, '/')
var aiServiceAccountSubscriptionId = aiServicePassedIn ? aiServiceAccountParts[2] : subscription().subscriptionId
var aiServiceAccountResourceGroupName = aiServicePassedIn ? aiServiceAccountParts[4] : resourceGroup().name

var managedIdentityName = '${accountName}-managed-identity-${uniqueSuffix}'

// Module deployments

// Managed Identity
module managedIdentity 'modules/managed_identity.bicep' = {
  name: 'deploy_managed_identity'
  params: {
    name: managedIdentityName
    location: location
  }
  scope: resourceGroup(resourceGroup().name)
}


// Dependencies
module dependencies 'modules/dependencies.bicep' = {
  name: 'dependencies-${accountName}-${uniqueSuffix}-deployment'
  params: {
    location: location
    azureStorageName: azureStorageName
    aiSearchName: aiSearchName
    cosmosDBName: cosmosDBName
    aiSearchResourceId: aiSearchResourceId
    azureStorageAccountResourceId: azureStorageAccountResourceId
    cosmosDBResourceId: azureCosmosDBAccountResourceId
    docsContainerName: docsContainerName
    artifactsContainerName: artifactsContainerName
    logAnalyticsName: logAnalyticsName
    insightsName: insightsName
  }
}

// AI Services
module aiServices_module 'modules/ai-services.bicep' = {
  name: 'ai-${accountName}-${uniqueSuffix}-deployment'
  params: {
    accountName: accountName
    location: locationOpenai
    models: models
    cogServicesName: cogServicesName
  }
  dependsOn: [
    dependencies
  ]
}

// AI Project
module aiProject 'modules/ai-project.bicep' = {
  name: 'ai-${projectName}-${uniqueSuffix}-deployment'
  params: {
    projectName: projectName
    projectDescription: projectDescription
    displayName: displayName
    location: locationOpenai
    aiSearchName: dependencies.outputs.aiSearchName
    aiSearchServiceResourceGroupName: dependencies.outputs.aiSearchServiceResourceGroupName
    aiSearchServiceSubscriptionId: dependencies.outputs.aiSearchServiceSubscriptionId
    cosmosDBName: dependencies.outputs.cosmosDBName
    cosmosDBSubscriptionId: dependencies.outputs.cosmosDBSubscriptionId
    cosmosDBResourceGroupName: dependencies.outputs.cosmosDBResourceGroupName
    azureStorageName: dependencies.outputs.azureStorageName
    azureStorageSubscriptionId: dependencies.outputs.azureStorageSubscriptionId
    azureStorageResourceGroupName: dependencies.outputs.azureStorageResourceGroupName
    accountName: aiServices_module.outputs.accountName
  }
}

// Storage Role Assignments
module storageRoleAssignments 'modules/storage-role-assignments.bicep' = {
  name: 'storage-${azureStorageName}-${uniqueSuffix}-deployment'
  scope: resourceGroup(azureStorageSubscriptionId, azureStorageResourceGroupName)
  params: {
    azureStorageName: dependencies.outputs.azureStorageName
    projectPrincipalId: aiProject.outputs.projectPrincipalId
    searchServicePrincipalId: dependencies.outputs.aiSearchServicePrincipalId
    principalId: principalId
    managedIdentityPrincipalId: managedIdentity.outputs.managedIdentityOutput.objectId
  }
}

// Cosmos DB Role Assignments
module cosmosRoleAssignments 'modules/cosmos-role-assignments.bicep' = {
  name: 'cosmos-account-ra-${uniqueSuffix}-deployment'
  scope: resourceGroup(cosmosDBSubscriptionId, cosmosDBResourceGroupName)
  params: {
    cosmosDBName: dependencies.outputs.cosmosDBName
    projectPrincipalId: aiProject.outputs.projectPrincipalId
  }
}

// Search Role Assignments
module searchRoleAssignments 'modules/search-role-assignments.bicep' = {
  name: 'ai-search-ra-${uniqueSuffix}-deployment'
  scope: resourceGroup(aiSearchServiceSubscriptionId, aiSearchServiceResourceGroupName)
  params: {
    aiSearchName: dependencies.outputs.aiSearchName
    projectPrincipalId: aiProject.outputs.projectPrincipalId
    userPrincipalId: principalId
  }
}

// Capability Host Configuration
module capabilityHostConfig 'modules/capability-host.bicep' = {
  name: 'capabilityHost-configuration-${uniqueSuffix}-deployment'
  params: {
    accountName: aiServices_module.outputs.accountName
    projectName: aiProject.outputs.projectName
    cosmosDBConnection: aiProject.outputs.cosmosDBConnection
    azureStorageConnection: aiProject.outputs.azureStorageConnection
    aiSearchConnection: aiProject.outputs.aiSearchConnection
    projectCapHost: projectCapHost
    accountCapHost: accountCapHost
  }
}

// Create Storage Containers
module storageContainers 'modules/storage-containers.bicep' = {
  name: 'storage-containers-${uniqueSuffix}-deployment'
  scope: resourceGroup(azureStorageSubscriptionId, azureStorageResourceGroupName)
  params: {
    aiProjectPrincipalId: aiProject.outputs.projectPrincipalId
    storageName: dependencies.outputs.azureStorageName
    workspaceId: aiProject.outputs.projectWorkspaceIdGuid
  }
}

// Cosmos DB Detailed Role Assignments
module cosmosDetailedRoleAssignments 'modules/cosmos-detailed-roles.bicep' = {
  name: 'cosmos-ra-${uniqueSuffix}-deployment'
  scope: resourceGroup(cosmosDBSubscriptionId, cosmosDBResourceGroupName)
  params: {
    cosmosAccountName: dependencies.outputs.cosmosDBName
    projectWorkspaceId: aiProject.outputs.projectWorkspaceIdGuid
    projectPrincipalId: aiProject.outputs.projectPrincipalId
  }
}

// AI Service Role Assignments
module aiServiceRoleAssignments 'modules/ai-service-role-assignments.bicep' = {
  name: 'ai-service-role-assignments-${projectName}-${uniqueSuffix}-deployment'
  scope: resourceGroup(aiServiceAccountSubscriptionId, aiServiceAccountResourceGroupName)
  params: {
    aiServicesName: aiServices_module.outputs.accountName
    aiProjectPrincipalId: aiProject.outputs.projectPrincipalId
    aiProjectId: aiProject.outputs.projectId
    searchServiceName: dependencies.outputs.aiSearchName
    userPrincipalId: principalId
    cogServicesName: aiServices_module.outputs.cogServicesName
    managedIdentityPrincipalId: managedIdentity.outputs.managedIdentityOutput.objectId
  }
}



// Outputs 
output AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT string = 'https://${cogServicesName}.cognitiveservices.azure.com'
output AZURE_STORAGE_ACCOUNT_URL string = 'https://${dependencies.outputs.azureStorageName}.blob.core.windows.net'
output AZURE_STORAGE_ACCOUNT_NAME string = dependencies.outputs.azureStorageName
output AOAI_API_BASE string = aiServices_module.outputs.accountTarget
output AOAI_API_VERSION string = '2025-03-01-preview'
output AOAI_LLM_MODEL string = length(models) > 1 ? models[1].name : 'gpt-4.1'
output AOAI_LLM_DEPLOYMENT string = length(models) > 1 ? models[1].name : 'gpt-4.1'

// Outputs for environment variables
output PROJECT_ENDPOINT string = aiProject.outputs.projectEndpoint
output MODEL_DEPLOYMENTS array = aiServices_module.outputs.deployedModels
output AZURE_SEARCH_ENDPOINT string = 'https://${dependencies.outputs.aiSearchName}.search.windows.net'
output AZURE_OPENAI_ENDPOINT string = 'https://${aiServices_module.outputs.accountName}.openai.azure.com'
output APPLICATION_INSIGHTS_CONNECTION_STRING string = dependencies.outputs.applicationInsightsConnectionString

