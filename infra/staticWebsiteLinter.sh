#!/bin/bash

# source params.sh from the same directory as this script
# this needs to work even if THIS script is called from another directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $DIR/params.sh
echo "location=$location, resourceGroupName=$resourceGroupName, storageAccountName=$storageAccountName"

# Check for resourceGroupName, storageAccountName, and location and exit if not set
if [ -z "$resourceGroupName" ] || [ -z "$storageAccountName" ] || [ -z "$location" ]; then
   echo "resourceGroupName, storageAccountName, and location must be set in params.sh"
   echo "Exiting..."
   exit 0
else
   echo "✅ resourceGroupName, storageAccountName, and location are set."
fi

# Ensure logged in
if ! az account show; then
   az login
fi

# Check for the existence of the resource group, exit if not exists
if ! az group exists --name $resourceGroupName; then
   echo "Resource group \"$resourceGroupName\" does NOT exist."
   echo "Exiting..."
   exit 0
else
   echo "✅ Resource group \"$resourceGroupName\" already exists."
fi

# Check for the existence of the storage account, exit if not exists
if az storage account check-name --name $storageAccountName --query 'nameAvailable'; then
   echo "Storage account \"$storageAccountName\" does NOT exist (and name is available)."
   echo "Exiting..."
   exit 0
else
   # echo green checkmark unicode character
   echo "✅ Storage account \"$storageAccountName\" already exists."
fi

echo "----------------------"
echo "az storage account show --name $storageAccountName --resource-group $resourceGroupName"
az storage account show --name $storageAccountName --resource-group $resourceGroupName

echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

az storage account show --name $storageAccountName --resource-group $resourceGroupName --query id --output tsv
echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0


saResourceId=$(az storage account show --name $storageAccountName --resource-group $resourceGroupName --query id --output tsv)
# check for saResourceId, exit if not exists
if [ -z "$saResourceId" ]; then
   echo "Storage account resource ID \"$saResourceId\" does NOT exist."
   echo "Exiting..."
   exit 0
fi
echo "Storage account resource ID: $saResourceId (for storage account $storageAccountName)"

az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties 

# list contents of the $web container
az storage blob list --account-name $storageAccountName --container-name '$web' --output table

# Show the URL of the static website
az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
url=$(az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
echo "url = $url"
open $url

echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0


# Get the connection string of the storage account
echo "__xx__"
connectionString=$(az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --query connectionString --output tsv)

# Set the static website properties
echo "__yyy__"
az storage blob service-properties update --account-name $storageAccountName --static-website --404-document "404.html" --index-document "index.html" --connection-string $connectionString

# Set the public access level of the $web container to blob
echo "__zzzz__"
az storage container set-permission --name '$web' --public-access blob --connection-string $connectionString

# Get the storage account resource ID
echo "__AAAA__"
saResourceId=$(az storage account show --name $storageAccountName --resource-group $resourceGroupName --query id --output tsv)
echo "Storage account resource ID: $saResourceId (for storage account $storageAccountName)"

echo "" ; echo "___ hang in there ___" ; echo "" 

echo "az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'"

# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess, .allowPublicAccess'

# Update the storage account properties to allow public access
az resource update --ids $saResourceId --set properties.allowBlobPublicAccess=true

# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
# az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess, .allowPublicAccess'
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'

# echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

# Upload contents of /src to the Azure blob storage
echo "Uploading contents of /src to $storageAccountName..."
az storage blob upload-batch --overwrite --account-name $storageAccountName --source src --destination '$web'

# Show the URL of the static website
az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
url=$(az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
echo "url = $url"
open $url

# az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv | xargs open

