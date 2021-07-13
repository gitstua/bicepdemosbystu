az group create -n bicep3 -l australiaeast
az deployment group create --template-file ./storage.bicep --resource-group bicep3
