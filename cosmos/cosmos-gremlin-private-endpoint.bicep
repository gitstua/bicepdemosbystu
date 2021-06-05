@maxLength(5)
@minLength(1)
@description('Environment')
param environment string = 'dev2'

@description('Cosmos DB account name')
param accountName string = '${environment}${uniqueString(resourceGroup().id)}'

@description('Location for the Cosmos DB account.')
param location string = resourceGroup().location

@description('The primary replica region for the Cosmos DB account.')
param primaryRegion string = resourceGroup().location

@description('The secondary replica region for the Cosmos DB account.')
param secondaryRegion string = 'australiasoutheast'

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
@description('The default consistency level of the Cosmos DB account.')
param defaultConsistencyLevel string = 'Session'

@minValue(10)
@maxValue(2147483647)
@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
param maxStalenessPrefix int = 100000

@minValue(5)
@maxValue(86400)
@description('Max lag time (seconds). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
param maxIntervalInSeconds int = 300

@allowed([
  true
  false
])
@description('Enable automatic failover for regions')
param automaticFailover bool = true

@description('The name for the Gremlin database')
param databaseName string = uniqueString(resourceGroup().name)

@description('The name for the Gremlin graph')
param graphName string = 'graphName'

@description('The partition key for the database')
param partionKey string='/myPartitionKey'

@description('Name of Private Enpoint resource')
param privateEndpointName string = 'pe1'

@description('Name of VNET resource')
param virtualNetworkName string = 'vNet1'

var accountName_var = toLower(accountName)
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}
var locations = [
  {
    locationName: primaryRegion
    failoverPriority: 0
    isZoneRedundant: false
  }
  {
    locationName: secondaryRegion
    failoverPriority: 1
    isZoneRedundant: false
  }
]

resource accountName_resource 'Microsoft.DocumentDB/databaseAccounts@2021-01-15' = {
  name: accountName_var
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    capabilities: [
      {
        name: 'EnableGremlin'
      }
    ]
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: automaticFailover
  }
}

resource accountName_databaseName 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases@2021-01-15' = {
  name: '${accountName_resource.name}/${databaseName}'
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource accountName_databaseName_graphName 'Microsoft.DocumentDb/databaseAccounts/gremlinDatabases/graphs@2021-01-15' = {
  name: '${accountName_databaseName.name}/${graphName}'
  properties: {
    resource: {
      id: graphName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/myPathToNotIndex/*'
          }
        ]
      }
      partitionKey: {
        paths: [
          partionKey
        ]
        kind: 'Hash'
      }
    }
    options: {
      throughput: 400
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subNet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: accountName_resource.id
          groupIds: [
            'Gremlin'
          ]
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.20.0.0/16'
      ]
    }
  }
}

resource subNet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  name: '${virtualNetwork.name}/default'
  properties: {
    addressPrefix: '172.20.0.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}
