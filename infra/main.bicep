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

// resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
//   name: storageAccountName
// }

// resource staticWebsite 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
//   parent: storageAccount
//   name: 'default'
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
  // staticWebsite: {
  //   enabled: true
  //   indexDocument: 'index.html'
  //   errorDocument404Path: '404.html'
  // }
}

resource saBlobService 'Microsoft.Storage/storageAccounts/blobServices@2023-04-01' = {
  parent: sa
  name: 'default'
  // sku: {
    // name: 'Standard_LRS'
    // tier: 'Standard'
  // }
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
  // dependsOn: [
  //   storageAccounts_cleanweb34_name_resource
  // ]
}


/*resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: accessTier
    isHnsEnabled: true // Enable Hierarchical Namespace
    // enableHttpsTrafficOnly: true // Enable HTTPS traffic only
    allowBlobPublicAccess: true // Allow public access to blobs

    staticWebsite: {
      enabled: true // Enable static website
      indexDocument: 'index.html' // Specify the index document
      error404Document: '404.html' // Specify the 404 error document
    }
  }
}
*/
