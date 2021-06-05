# bicepdemosbystu

## Links
https://docs.microsoft.com/en-us/azure/cosmos-db/templates-samples-gremlin

## Example to deploy cosmos
az group create --resource-group aaaa --location australiaeast
az deployment group create --name firstbicep2 --resource-group aaaa  --template-file cosmos/cosmos-gremlin-private-endpoint.bicep