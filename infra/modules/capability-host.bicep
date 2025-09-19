param cosmosDBConnection string
param azureStorageConnection string
param aiSearchConnection string
param projectName string
param accountName string
param projectCapHost string
param accountCapHost string

var threadConnections = [
  cosmosDBConnection
]
var storageConnections = [
  azureStorageConnection
]
var vectorStoreConnections = [
  aiSearchConnection
]

// Account Capability Host
resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = {
  name: '${accountName}/${accountCapHost}'
  properties: {
    capabilityHostKind: 'Agents'
  }
}

// Project Capability Host
resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = {
  name: '${accountName}/${projectName}/${projectCapHost}'
  properties: {
    capabilityHostKind: 'Agents'
    vectorStoreConnections: vectorStoreConnections
    storageConnections: storageConnections
    threadStorageConnections: threadConnections
  }
  dependsOn: [
    accountCapabilityHost
  ]
}
