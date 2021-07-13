az group create -n bicepmodule1 -l australiaeast
az deployment group create --template-file ./main.bicep --resource-group bicepmodule1
