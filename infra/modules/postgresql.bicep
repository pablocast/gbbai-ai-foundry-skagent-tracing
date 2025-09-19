@description('Server Name for Azure database for PostgreSQL Flexible Server')
param serverName string = 'pgflexserver-${uniqueString(resourceGroup().id)}'

@description('Database administrator login name')
@minLength(1)
param administratorLogin string = 'pgadmin'

@description('Database administrator password')
@minLength(8)
@secure()
param administratorLoginPassword string = '${uniqueString(resourceGroup().id, deployment().name)}Aa1!'
param allowAllIPsFirewall bool = true
param allowAzureIPsFirewall bool = true
param allowedSingleIPs array = []

param entraAdministratorName string 
param entraAdministratorObjectId string 
param entraAdministratorType string

@description('Azure database for PostgreSQL pricing tier')
@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
  'Burstable'
])
param skuTier string = 'GeneralPurpose'

@description('Azure database for PostgreSQL Flexible Server sku name ')
param skuName string = 'Standard_D2ds_v4'

@description('Azure database for PostgreSQL Flexible Server Storage Size in GB ')
param storageSize int = 32

@description('PostgreSQL version')
@allowed([
  '11'
  '12'
  '13'
  '14'
  '15'
  '16'
])
param version string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('PostgreSQL Flexible Server backup retention days')
param backupRetentionDays int = 7

@description('Geo-Redundant Backup setting')
@allowed([
  'Disabled'
  'Enabled'
])
param geoRedundantBackup string = 'Disabled'

@description('High Availability Mode')
@allowed([
  'Disabled'
  'ZoneRedundant'
  'SameZone'
])
param haMode string = 'Disabled'

@description('Active Directory Authetication')
@allowed([
  'Disabled'
  'Enabled'
])
param isActiveDirectoryAuthEnabled string = 'Enabled'

@description('PostgreSQL Authetication')
@allowed([
  'Disabled'
  'Enabled'
])
param isPostgreSQLAuthEnabled string = 'Enabled'

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'pgflexserver-identity'
  location: location
  tags: {}
}

@description('PostgreSQL Authentication Type')
@allowed([
  'EntraOnly'
  'PostgreSQLOnly'
  'EntraAndPostgreSQL'
])
param authType string 

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    createMode: 'Default'
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    authConfig: {
      authType: authType
      activeDirectoryAuth: isActiveDirectoryAuthEnabled
      passwordAuth: isPostgreSQLAuthEnabled
      tenantId: subscription().tenantId
    }
      storage: {
        storageSizeGB: storageSize
      }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: haMode
    }
  }
}

resource addAddUser 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  name: concat(serverName, '/', entraAdministratorObjectId)
  dependsOn: [server, firewall_all, firewall_azure]
  properties: {
    tenantId: subscription().tenantId
    principalType: entraAdministratorType
    principalName: entraAdministratorName
  }
}

// This must be done separately due to conflicts with the Entra setup
resource firewall_all 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = if (allowAllIPsFirewall) {
  parent: server
  name: 'allow-all-IPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource firewall_azure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = if (allowAzureIPsFirewall) {
  parent: server
  name: 'allow-all-azure-internal-IPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

@batchSize(1)
// This must be done separately due to conflicts with the Entra setup
resource firewall_single 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = [for ip in allowedSingleIPs: {
  parent: server
  name: 'allow-single-${replace(ip, '.', '')}'
  properties: {
    startIpAddress: ip
    endIpAddress: ip
  }
}]


// Workaround issue https://github.com/Azure/bicep-types-az/issues/1507
resource configurations 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-03-01-preview' = {
  name: 'azure.extensions'
  parent: server
  properties: {
    value: 'vector, azure_ai, age'
    source: 'user-override'
  }
  dependsOn: [
     addAddUser, firewall_all, firewall_azure, firewall_single
  ]
}

// Configuration for shared_preload_libraries
resource sharedPreloadLibrariesConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-03-01-preview' = {
  name: 'shared_preload_libraries'
  parent: server
  properties: {
    value: 'age'
    source: 'user-override'
  }
  dependsOn: [
    configurations // Ensure it depends on azure.extensions configuration
  ]
}

output POSTGRES_HOST string = server.properties.fullyQualifiedDomainName
output POSTGRES_DATABASE_NAME string = 'postgres'
output POSTGRES_USERNAME string = administratorLogin
output POSTGRES_PASSWORD string = administratorLoginPassword
output POSTGRES_SSLMODE string = 'require'
