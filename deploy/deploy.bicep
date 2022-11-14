param location string = resourceGroup().location
param hostingPlanName string = 'philipwap-${uniqueString(resourceGroup().id)}'
param functionAppName string = 'philipfn-${uniqueString(resourceGroup().id)}'
param storageAccountName string = 'fnstor${uniqueString(resourceGroup().id)}'
param dockerRegistry string ='begim'
param imageSha string = 'begimfuncpydemo:latest'


@secure()
param password string 


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

/*
resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'elastic'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  properties: {
    maximumElasticWorkerCount: 1
    reserved: true
  }
}

*/

resource webHostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'S1'
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    elasticScaleEnabled: false
    //maximumElasticWorkerCount: 1
    reserved: true
    zoneRedundant: false
  }
}


// It has not been possible to deploy this successfully through bicep
// The function app will deploy and look all right, but the DOCKER will
// not deploy properly. The function app must be deployed through the
// Azure portal. This script can then be run afterwards to update and
// set all settings.
resource FunctionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: functionAppName
  kind: 'functionapp,linux,container'
  location: location
  tags: {
    Owner: 'Phkj'
    Product: 'ApiService'
    EnvironmentType: 'development'
  }
  properties: {
    enabled: true
    serverFarmId: webHostingPlan.id
    reserved: true
    isXenon: false
    hyperV: false
    vnetRouteAllEnabled: false
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: false
    redundancyMode: 'None'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
    hostNameSslStates: [
      {
        name: 'func-api-dev-ne2.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: 'func-api-dev-ne2.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    siteConfig: {
      localMySqlEnabled: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      linuxFxVersion: 'DOCKER|${dockerRegistry}.azurecr.io/${imageSha}'
      acrUseManagedIdentityCreds: false
      //alwaysOn: true // should not be set for funcs hosting, only App Service plan hosting
      http20Enabled: false
      functionAppScaleLimit: 0
      //minimumElasticInstanceCount: 0
      appSettings: [ 
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistry
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: password
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${dockerRegistry}.azurecr.io'
        }
      ]
    }
  }
}

resource FunctionAppSiteConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'web'
  kind: 'string'
  parent: FunctionApp
  properties: {
    localMySqlEnabled: false
    ftpsState: 'Disabled'
    minTlsVersion: '1.2'
    linuxFxVersion: 'DOCKER|${dockerRegistry}.azurecr.io/${imageSha}'
    acrUseManagedIdentityCreds: false
    //alwaysOn: true // should not be set for funcs hosting, only App Service plan hosting
    http20Enabled: false
    functionAppScaleLimit: 0
    //minimumElasticInstanceCount: 0
  }
}
