// Define Azure resources for deployment

// Notably, for those learning Bicep, there is an Azure Subscription 
// and a Resource Group within that Subscription into which we are
// deploying the other resources modeled within this file. Those
// details do not appear in this file, but are determined by the
// deployment script that references this .bicep file.

@description('The name of the storage account.')
param storageAccountName string // pass in as param

@description('The location of the resources.')
param location string = 'eastus2' // pass in as param or use this as default

@description('The SKU of the storage account.')
param storageAccountSku string = 'Standard_LRS'

@description('The access tier of the storage account.')
param accessTier string = 'Hot'

// https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website-how-to?tabs=azure-cli
// https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-static-website#setting-up-a-static-website
// https://devblogs.microsoft.com/devops/comparing-azure-static-web-apps-vs-azure-webapps-vs-azure-blob-storage-static-sites/


resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
      name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
      allowBlobPublicAccess: true
      accessTier: accessTier
      supportsHttpsTrafficOnly: true
  }
}

resource saBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: sa
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource saWebContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-04-01' = {
  parent: saBlobService
  name: '$web'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'Blob'
  }
}
