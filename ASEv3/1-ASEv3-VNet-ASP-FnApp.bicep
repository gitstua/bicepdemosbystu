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
@description('the name of the ase e.g. myexample')
param aseName string = 'ase-${baseName}'
param location string = resourceGroup().location
//param dedicatedHostCount int = 0
// param zoneRedundant bool
param virtualNetworkName string = '${baseName}vnet1'
param virtualNetworkAddress string = '10.111.0.0/16'
//todo: pass in subnets in an array rather than lots of params
param subnetNameAse string = '${baseName}subnetAse'
param subnetAddressAse string =  '10.111.0.0/24'
param subnetName2 string = '${baseName}subnet2'
param subnetAddress2 string =  '10.111.1.0/24'
param subnetName3 string = '${baseName}subnet3'
param subnetAddress3 string =  '10.111.3.0/24'
param delegationName string= '${baseName}delegation1'
param ilbMode string ='Web, Publishing'
param privateZoneName string = '${baseName}zone1.appserviceenvironment.net'

var subnetAseId = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetNameAse}'
var subnet2Id = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetAddress2}'

//Note: this next resource must be created after the resources in this template so has been 
//      moved to another script since they must be created after the ASE is ready
// resource webHostingFarm 'Microsoft.Web/serverfarms@2020-06-01' ={
//   kind: 'linux'
//   name: '${aseName}-ASP2'
//   location: location
//   properties:{
//     hostingEnvironmentProfile: {
//       id: ase_resource.id
//     }
//     // note: this must be set to true to deploy linux
//     reserved: true
//   }
//   sku: {
//     name: 'I1v2'
//       tier: 'IsolatedV2'
//       size: 'I1v2'
//       family: 'Iv2'
//       capacity: 1
//   }
//   dependsOn:[
//     ase_resource
//   ]
// }

resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2021-02-01' = {
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
        name: subnetNameAse
        properties: {
          addressPrefix: subnetAddressAse
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
      {
        name: subnetName2
        properties: {
          addressPrefix: subnetAddress2
        }
      }      
      {
        name: subnetName3
        properties: {
          addressPrefix: subnetAddress3
        }
      }
    ]
  }
}

resource ase_resource 'Microsoft.Web/hostingEnvironments@2020-12-01' = {
  name: aseName
  kind: 'ASEV3'
  location: location
  properties: {
    //note: Bicep flags this next line as an error which can be ignored
    //dedicatedHostCount: dedicatedHostCount
    // zoneRedundant: zoneRedundant
     internalLoadBalancingMode: ilbMode
    virtualNetwork: {
      id: subnetAseId
    }
  }
  tags: null
  dependsOn: [
    virtualNetwork_resource
  ]
}

resource privateZone_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateZoneName
  location: 'global'
  tags: null
  properties: {}
  dependsOn: [
    ase_resource
  ]
}

resource privateZone_vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  parent: privateZone_resource
  name: 'vnetLink'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetwork_resource.id
    }
    registrationEnabled: false
  }
}

resource privateZone_wildcard 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZone_resource
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${ase_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}

resource privateZone_scm 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZone_resource
  name: '*.scm'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${ase_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}

resource privateZone_apex 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: privateZone_resource
  name: '@'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: reference('${ase_resource.id}/configurations/networking', '2019-08-01').internalInboundIpAddresses[0]
      }
    ]
  }
}


output subnetAseId string = subnetAseId
output subnet2Id string = subnet2Id
output virtualNetworkId string = virtualNetwork_resource.id
output myresource object = virtualNetwork_resource
