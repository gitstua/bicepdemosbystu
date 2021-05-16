# bicepdemosbystu

## Links
https://docs.microsoft.com/en-us/azure/cosmos-db/templates-samples-gremlin

## Example to deploy cosmos
az group create -g myResourceGroup -l australiaeast
az deployment group create \
  --name firstbicep \
  --resource-group myResourceGroup \
  --template-file cosmos/cosmos-gremlin.bicep

az deployment group create \
  --name firstbicep \
  --resource-group myResourceGroup \
  --template-file cosmos/cosmos-gremlin-private-endpoint.bicep

  