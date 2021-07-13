param aseName string
param location string
param subscriptionId string
param dedicatedHostCount string
param virtualNetworkName string
param virtualNetworkResourceGroupName string
param virtualNetworkAddress string
param inboundSubnetName string
param inboundSubnetId string
param inboundSubnetAddress string
param outboundSubnetName string
param outboundSubnetId string
param outboundSubnetAddress string
param delegationName string
param privateEndpointConnectionName string
param privateLinkConnectionName string
param hostingEnvironmentId string
param ilbMode int

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2018-04-01' = {
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
        name: inboundSubnetName
        properties: {
          addressPrefix: inboundSubnetAddress
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: outboundSubnetName
        properties: {
          addressPrefix: outboundSubnetAddress
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

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2019-08-01' = {
  name: aseName
  kind: 'ASEV3'
  location: location
  properties: {
    dedicatedHostCount: dedicatedHostCount
    internalLoadBalancingMode: ilbMode
    virtualNetwork: {
      id: outboundSubnetId
    }
  }
  tags: null
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource privateEndpointConnectionName_resource 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: privateEndpointConnectionName
  location: location
  properties: {
    subnet: {
      id: inboundSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: hostingEnvironmentId
          groupIds: [
            'hostingEnvironments'
          ]
        }
      }
    ]
  }
  dependsOn: [
    aseName_resource
  ]
}