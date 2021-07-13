param baseName string = 'zzz10'
param location string = 'australiaeast'

module asev3 'ASEv3-VNet-ASP-FnApp.bicep' = {
  name: 'asev3deploy'
  params: {
    aseName: baseName
    location: location
  }
}

// resource asev3virtualNetworkId 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
//   name: 'aaa' 
// }

// resource apim 'Microsoft.ApiManagement/service@2020-12-01' = {
// sku: {
//   capacity: 
// }
// }



output asev3subnetAseId string = asev3.outputs.subnetAseId
output asev3subnet2Id string = asev3.outputs.subnet2Id
//output asev3virtualNetworkId string = asev3.outputs.virtualNetworkId
