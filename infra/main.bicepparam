using './main.bicep'

param location = 'westus'
param locationOpenai = 'westus'
param aiServices = 'foundry'
param firstProjectName = 'project'
param projectDescription = 'some description'
param displayName = 'project'
param models = [
  {
    name: 'gpt-4o'
    format: 'OpenAI'
    version: '2024-11-20'
    skuName: 'GlobalStandard'
    capacity: 450
  }
  {
    name: 'gpt-4.1'
    format: 'OpenAI'
    version: '2025-04-14'
    skuName: 'GlobalStandard'
    capacity: 1000
  }
]
param aiSearchResourceId = ''
param azureStorageAccountResourceId = ''
param azureCosmosDBAccountResourceId = ''
param projectCapHost = 'caphostproj'
param accountCapHost = 'caphostacc'
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', 'principalId')
