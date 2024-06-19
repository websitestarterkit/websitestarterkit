#!/bin/bash

echo ""
echo "------------------------------------------------------------"
echo "Beginning incremental deployment at $(date)."
echo "------------------------------------------------------------"
echo ""

# A few things need to happen:
# 1. Create a resource group if it doesn't exist
# 2. Deploy the resources using the Bicep file
# 3. Create the special '$web' container within Azure blob storage
# 4. Ensure that the storage account properties allow public access
# 5. Ensure that the $web container allows public access
# 6. Upload the contents of /src to the $web container

# 1-5 are handled by config.sh (and 6, but that's repeated in this file)

# source params.sh from the same directory as this script
# this needs to work even if THIS script is called from another directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $DIR/params.sh
echo "location=$location, resourceGroupName=$resourceGroupName, storageAccountName=$storageAccountName"

# Ensure logged in (for interactive use of this script in a shell).
# You would not invoke "az login" in a script that runs unattended
# such as from a GitHub Action (where there are other ways to 
# authenticate).
if ! az account show; then
  az login
fi

# Upload contents of /src to the Azure blob storage
echo "Uploading contents of /src to $storageAccountName..."
src=$DIR/../src
connectionString=$(az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --query connectionString --output tsv)
# echo "az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString"
az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString

# Show the URL of the static website by querying via cli
# az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
url=$(az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
echo "url = $url"
open $url

echo "Deployment completed at $(date)."
