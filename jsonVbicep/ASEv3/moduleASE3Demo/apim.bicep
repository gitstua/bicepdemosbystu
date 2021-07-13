@description('the name of the ase e.g. myexample - this is used to name the other resources')
param baseName string = 'ase-${resourceGroup().name}'
param apimName string = 'apim4-${baseName}'
param location string = resourceGroup().location
param vNetName string = '${baseName}vnet1'
param subnetName  string = '${baseName}subnet2'
param publisherName string = 'publisherName'
param publisherEmail string = 'publisherEmail@contoso.com'
@allowed([
    'Developer'
    'Premium'
    'Isolated'
  ])
param apimSkuName string = 'Developer'


resource vNet 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: vNetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  parent: vNet
  name: subnetName
}

resource apiManagementInstance 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: apimName
  location: location
  sku:{
    capacity: 1
    name: apimSkuName
  }
  properties:{
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: subnet.id
    }
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
  // identity: {
  //   type: 'SystemAssigned'
  // }
}
