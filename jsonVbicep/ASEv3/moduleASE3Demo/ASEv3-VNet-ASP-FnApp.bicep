@description('the name of the ase e.g. myexample - this is used to name the other resources')
param aseName string = 'ase-${resourceGroup().name}'
param location string = resourceGroup().location
param dedicatedHostCount int = 0
// param zoneRedundant bool
param virtualNetworkName string = '${aseName}vnet1'
param virtualNetworkAddress string = '10.111.0.0/16'
//todo: pass in subnets in an array rather than lots of params
param subnetNameAse string = '${aseName}subnetAse'
param subnetAddressAse string =  '10.111.0.0/24'
param subnetName2 string = '${aseName}subnet2'
param subnetAddress2 string =  '10.111.1.0/24'
param subnetName3 string = '${aseName}subnet3'
param subnetAddress3 string =  '10.111.3.0/24'
param delegationName string= '${aseName}delegation1'
param ilbMode string ='Web, Publishing'
param privateZoneName string = '${aseName}zone1.appserviceenvironment.net'

var subnetAseId = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetNameAse}'
var subnet2Id = '${resourceGroup().id}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetAddress2}'

// resource webHostingFarm 'Microsoft.Web/serverfarms@2020-06-01' ={
//   kind: 'linux'
//   name: '${aseName}-ASP2'
//   location: location
//   properties:{
//     hostingEnvironmentProfile: {
//       id: aseName_resource.id
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
//     aseName_resource
//   ]
// }

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


resource aseName_resource 'Microsoft.Web/hostingEnvironments@2020-12-01' = {
  name: aseName
  kind: 'ASEV3'
  location: location
  properties: {
    //note: Bicep flags this next line as an error which can be ignored
    dedicatedHostCount: dedicatedHostCount
    // zoneRedundant: zoneRedundant
     internalLoadBalancingMode: ilbMode
    virtualNetwork: {
      id: subnetAseId
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


output subnetAseId string = subnetAseId
output subnet2Id string = subnet2Id
output virtualNetworkId string = virtualNetworkName_resource.id
output myresource object = virtualNetworkName_resource
