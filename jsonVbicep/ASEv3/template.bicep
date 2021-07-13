@description('the name of the ase e.g. myexample - this is used to name the other resources')
param aseName string = 'zzzase7'
param location string = resourceGroup().location
param dedicatedHostCount int = 0
// param zoneRedundant bool
param virtualNetworkName string = '${aseName}vnet1'
param virtualNetworkAddress string = '10.111.0.0/16'
param subnetName string = '${aseName}subnet1'
param subnetAddress string =  '10.111.0.0/16'
param delegationName string= '${aseName}delegation1'
param ilbMode string ='Web, Publishing'
param privateZoneName string= '${aseName}zone1.appserviceenvironment.net'
@description('the name of the storage account (must be lowercase and 3-24 chars)')
@maxLength(24)
@minLength(3)
param functionAppStorageName string = uniqueString(resourceGroup().id)
param functionAppName string = '${aseName}FnApp1'

var subnetId = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'

resource functionApp 'Microsoft.Web/sites@2021-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties:{
    siteConfig:{
      alwaysOn: true
      use32BitWorkerProcess: false
      linuxFxVersion: 'Python|3.9'
      windowsFxVersion: null
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        } 
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: 'tbc'
        }
        {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: 'tbc'
        }
        {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${functionAppStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionAppStorage.id, functionAppStorage.apiVersion).keys[0].value}'
        }
      ]
    }
    serverFarmId: webHostingFarm.id
    hostingEnvironmentProfile: {
      id: aseName_resource.id
    }
    clientAffinityEnabled: false
  }
}

resource functionAppStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  location: location
  name: functionAppStorageName
  kind: 'Storage'
  sku: {
    name: 'Standard_GRS' // assign variable
  }
  properties:{
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource webHostingFarm 'Microsoft.Web/serverfarms@2021-01-01' ={
  kind: 'linux'
  name: '${aseName}-ASP2'
  location: location
  properties:{
    hostingEnvironmentProfile: {
      id: aseName_resource.id
    }
    // note: this must be set to true to deploy linux
    reserved: true
  }
  sku: {
    name: 'I1v2'
      tier: 'IsolatedV2'
      size: 'I1v2'
      family: 'Iv2'
      capacity: 1
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddress
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddress
          delegations: [
            {
              name: delegationName
              properties: {
                serviceName: 'Microsoft.Web/hostingEnvironments'
              }
            }
          ]
        }
      }
    ]
  }
}


resource aseName_resource 'Microsoft.Web/hostingEnvironments@2021-01-01' = {
  name: aseName
  kind: 'ASEV3'
  location: location
  properties: {
    dedicatedHostCount: dedicatedHostCount
    // zoneRedundant: zoneRedundant
     internalLoadBalancingMode: ilbMode
    virtualNetwork: {
      id: subnetId
    }
  }
  tags: null
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource privateZoneName_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateZoneName
  location: 'global'
  tags: null
  properties: {}
  dependsOn: [
    aseName_resource
  ]
}

resource privateZoneName_vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateZoneName_resource
  name: 'vnetLink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkName_resource.id
    }
    registrationEnabled: false
  }
}

resource privateZoneName_wildcard 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZoneName_resource
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${aseName_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}

resource privateZoneName_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZoneName_resource
  name: '*.scm'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${aseName_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}

resource privateZoneName_apex 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZoneName_resource
  name: '@'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${aseName_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}


output secretUri string = subnetId
