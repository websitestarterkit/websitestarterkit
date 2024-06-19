#!/bin/bash

echo ""
echo "------------------------------------------------------------"
echo "Beginning deployment at $(date)."
echo "------------------------------------------------------------"
echo ""

# A few things need to happen:
# 1. Create a resource group if it doesn't exist
# 2. Deploy the resources using the Bicep file
# 3. Create the special '$web' container within Azure blob storage
# 4. Upload the contents of /src to the $web container
# 5. Ensure that the storage account properties allow public access
# 6. Ensure that the $web container allows public access



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
fi

# Check if the resource group exists
rg_exists=$(az group exists --name $resourceGroupName)
echo "rg_exists=$rg_exists"
# if [ "$rg_exists" == "true" ]; then
#   echo "→ Resource group $resourceGroupName exists."
# else
#   echo "→ Resource group $resourceGroupName does NOT exist."
# fi

# Ensure logged in (for interactive use of this script in a shell).
# You would not invoke "az login" in a script that runs unattended
# such as from a GitHub Action (where there are other ways to 
# authenticate).
if ! az account show; then
  az login
fi

#   echo "✅ Resource group \"$resourceGroupName\" already exists."

if [ "$rg_exists" != "true" ]; then
  echo "Creating resource group: \"$resourceGroupName\""
  az group create --name $resourceGroupName --location $location
else
  echo "✅ Resource group \"$resourceGroupName\" already exists."
fi


# echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

# Deploy resources using Bicep file
echo "Applying Bicep model $DIR/main.bicep in resource group $resourceGroupName at $location..."
az deployment group create --resource-group $resourceGroupName --template-file $DIR/main.bicep --parameters storageAccountName=$storageAccountName
# az deployment group create --resource-group $resourceGroupName --template-file infra/main.bicep --parameters location=$location, storageAccountName=$storageAccountName

# echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

echo "------------------------------------------------------------"
echo "------------------------------------------------------------"

# create the special '$web' container
connectionString=$(az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --query connectionString --output tsv)
echo "connectionString = $connectionString"
### ?? az storage blob service-properties update --account-name $storageAccountName --static-website --404-document "404.html" --index-document "index.html" --connection-string $connectionString
# get storage account properties relevant for azure static websites (allowBlobPublicAccess, allowPublicAccess)
echo "ABOUT TO CALL: az storage account show --name $storageAccountName --resource-group $resourceGroupName --query properties | jq '.allowBlobPublicAccess, .allowPublicAccess'"
az storage account show --name $storageAccountName --resource-group $resourceGroupName --query properties | jq '.allowBlobPublicAccess, .allowPublicAccess'
echo "-- the above probably returned NOTHING --"
date

saResourceId=$(az storage account show --name $storageAccountName --resource-group $resourceGroupName --query id --output tsv)
echo "saResourceId = $saResourceId"
echo "az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'"

echo "/* _______________________________"
# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
# az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'

# Update the storage account properties to allow public access

# Bicep equivalent: properties: { allowBlobPublicAccess: true }
# az resource update --ids $saResourceId --set properties.allowBlobPublicAccess=true

# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'
echo "-- the above SHOULD HAVE returned 'true' --"

echo "/* _______________________________"


echo "+++++++++++++++++++++ PRE  +++++++++++++++++++++"
az storage blob service-properties show --account-name $storageAccountName --connection-string $connectionString
echo "+++++++++++++++++++++"
# Enable serving website content from the special '$web' container. Configure this before uploading to $web container.
# The following line (as of June 2024, as far as I can tell) does not have a pure bicep analog.
az storage blob service-properties update --account-name $storageAccountName --static-website --404-document "404.html" --index-document "index.html" --connection-string $connectionString
# show the values of the blob service properties
echo "+++++++++++++++++++++ POST +++++++++++++++++++++"
az storage blob service-properties show --account-name $storageAccountName --connection-string $connectionString
echo "+++++++++++++++++++++"



# Upload contents of /src to the Azure blob storage
echo "Uploading contents of /src to $storageAccountName..."
src=$DIR/../src
connectionString=$(az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --query connectionString --output tsv)
echo "az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString"
az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString


# Show the URL of the static website by querying via cli
az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
url=$(az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
echo "url = $url"
open $url


date
echo "Deployment completed at $(date)."




echo "------------------------------------------------------------"
echo "------------------------------------------------------------"
echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0






# Check for the existence of the storage account, create if not exists
sa_avail=$(az storage account check-name --name $storageAccountName --query 'nameAvailable')
echo "sa_avail=$sa_avail"

if [ "$sa_avail" == "true" ]; then
   echo "Storage account name \"$storageAccountName\" is available!"
   echo "Creating storage account: $storageAccountName"
   az storage account create --name $storageAccountName --resource-group $resourceGroupName --location $location --sku Standard_LRS
else
   echo "Storage account $storageAccountName already exists."
fi

# echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

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

echo "/* _______________________________"
# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'

# Update the storage account properties to allow public access
az resource update --ids $saResourceId --set properties.allowBlobPublicAccess=true

# Show status of storage account properties' allowBlobPublicAccess and allowPublicAccess
# az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess, .allowPublicAccess'
az resource show --ids $saResourceId --api-version 2021-04-01 --query properties | jq '.allowBlobPublicAccess'

echo "_______________________________ */"

# echo "" ; echo "___ bailing out ___" ; echo "" ; exit 0

# Upload contents of /src to the Azure blob storage
echo "Uploading contents of /src to $storageAccountName..."
src=$DIR/../src
az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString

# Show the URL of the static website by querying via cli
az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
url=$(az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
echo "url = $url"
open $url


date
echo "Deployment complete."
 