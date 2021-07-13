@description('the name of the ase e.g. myexample - this is used to name the other resources. must be in the resource group this template is deployed to.')
param aseName string = 'ase-${resourceGroup().name}'
param aseResourceGroupName string = resourceGroup().name
param location string = resourceGroup().location
param AppInsightsInstrumentationKey string = ''
param AppInsightsConnectionString string = ''

@description('the name of the storage account (must be lowercase and 3-24 chars)')
@maxLength(24)
@minLength(3)
param functionAppStorageName string = uniqueString(resourceGroup().id)
param functionAppName string = 'FnApp1-${aseName}'


//obtain a reference to the resource we created earlier
//this is required to be in a seperate template as the ASEv3 must be fully created and available (~2 hours of deployment) before this template is submitted
resource aseName_resource 'Microsoft.Web/hostingEnvironments@2020-12-01' existing = {
  name: aseName
  scope: resourceGroup(aseResourceGroupName)
}

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
          value: AppInsightsInstrumentationKey
        }
        {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: AppInsightsConnectionString
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
    allowBlobPublicAccess: false
  }
}

resource webHostingFarm 'Microsoft.Web/serverfarms@2020-06-01' ={
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
  dependsOn:[
    aseName_resource
  ]
}

// output subnetAseId string = subnetAseId
// output subnet2Id string = subnet2Id
// output virtualNetworkId string = virtualNetworkName_resource.id
// output myresource object = virtualNetworkName_resource
