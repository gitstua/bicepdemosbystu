/*  LICENCE SEE: https://github.com/gitstua/bicepdemosbystu/blob/main/LICENSE
    This template can be run by following these steps:
    1. Install Azure CLI or connect to Cloud Shell 
    2. Verify connected to the correct account 
    3. Create a resource group:
      az group create -l australiaeast -n myResourceGroup 
    4. Create a deployment
      az deployment group create -g myResourceGroup -f .\filename.bicep 

    NOTE: You can specify parameters if you choose. If not specified params are defaulted based on resourcegroup name 
          if specified resources are named based on baseName e.g. 
          az deployment group create -g MyResourceGroup --template-file filename.bicep --parameters baseName=dev34
*/

@description('the name of the ase e.g. myexample - this is used to name the other resources')
param baseName string = 'ase-${resourceGroup().name}'
param apimName string = 'apim-${baseName}'
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
