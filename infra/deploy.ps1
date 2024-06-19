$start_time = Get-Date -UFormat %s

Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host "Beginning incremental deployment at $(Get-Date)."
Write-Host "------------------------------------------------------------"
Write-Host ""

# A few things need to happen:
# 1. Create a resource group if it doesn't exist
# 2. Deploy the resources using the Bicep file
# 3. Create the special '$web' container within Azure blob storage
# 4. Ensure that the storage account properties allow public access
# 5. Ensure that the $web container allows public access
# 6. Upload the contents of /src to the $web container

# 1-5 are handled by config.ps1 (and 6, but that's repeated in this file)

# source params.ps1 from the same directory as this script
# this needs to work even if THIS script is called from another directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath/params.ps1"
Write-Host "location=$location, resourceGroupName=$resourceGroupName, storageAccountName=$storageAccountName"

# Ensure logged in (for interactive use of this script in a shell).
# You would not invoke "az login" in a script that runs unattended
# such as from a GitHub Action (where there are other ways to 
# authenticate).
if (-not (az account show)) {
  az login
}

# Upload contents of /src to the Azure blob storage
Write-Host "Uploading contents of /src to $storageAccountName..."
$src = "$scriptPath/../src"
$connectionString = (az storage account show-connection-string --name $storageAccountName --resource-group $resourceGroupName --query connectionString --output tsv)
az storage blob upload-batch --overwrite --account-name $storageAccountName --source $src --destination '$web' --connection-string $connectionString

# Show the URL of the static website by querying via cli
# az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv
$url = (az storage account show -n $storageAccountName -g $resourceGroupName --query "primaryEndpoints.web" -o tsv)
Write-Host "url = $url"
Start-Process $url

$end_time = Get-Date -UFormat %s
$runtime_seconds = $end_time - $start_time

Write-Host "Deployment at $(Get-Date) after $runtime_seconds seconds."

# Write-Host "Script runtime:  seconds"
