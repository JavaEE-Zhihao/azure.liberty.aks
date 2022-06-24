/*
     Copyright (c) Microsoft Corporation.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param _artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('User-assigned managed identity granted with contributor role of the same subscription')
param identity object

@description('Flag indicating whether to create a new cluster or not')
param createCluster bool = true

@description('The VM size of the cluster')
param vmSize string = 'Standard_DS2_v2'

@description('The minimum node count of the cluster')
param minCount int = 1

@description('The maximum node count of the cluster')
param maxCount int = 5

@description('Name for the existing cluster')
param clusterName string = ''

@description('Name for the resource group of the existing cluster')
param clusterRGName string = ''

@description('Flag indicating whether to create a new ACR or not')
param createACR bool = true

@description('Name for the existing ACR')
param acrName string = ''

@description('true to set up Application Gateway ingress.')
param enableAppGWIngress bool = false

@description('DNS prefix for ApplicationGateway')
param dnsNameforApplicationGateway string = 'olgw'

@allowed([
  'haveCert'
  'haveKeyVault'
  'generateCert'
])
@description('Three scenarios we support for deploying app gateway')
param appGatewayCertificateOption string = 'haveCert'

@description('Public IP Name for the Application Gateway')
param appGatewayPublicIPAddressName string = 'gwip'

@secure()
@description('The one-line, base64 string of the SSL certificate data.')
param appGatewaySSLCertData string = newGuid()

@secure()
@description('The value of the password for the SSL Certificate')
param appGatewaySSLCertPassword string = newGuid()

@description('Resource group name in current subscription containing the KeyVault')
param keyVaultResourceGroup string = 'kv-contoso-rg'

@description('Existing Key Vault Name')
param keyVaultName string = 'kv-contoso'

@description('Price tier for Key Vault.')
param keyVaultSku string = 'Standard'

@description('The name of the secret in the specified KeyVault whose value is the SSL Certificate Data for Appliation Gateway frontend TLS/SSL.')
param keyVaultSSLCertDataSecretName string = 'kv-ssl-data'

@description('The name of the secret in the specified KeyVault whose value is the password for the SSL Certificate of Appliation Gateway frontend TLS/SSL')
param keyVaultSSLCertPasswordSecretName string = 'kv-ssl-psw'

@secure()
@description('Base64 string of service principal. use the command to generate a testing string: az ad sp create-for-rbac --sdk-auth --role Contributor --scopes /subscriptions/<AZURE_SUBSCRIPTION_ID> | base64 -w0')
param servicePrincipal string = newGuid()

@description('true to enable cookie based affinity.')
param enableCookieBasedAffinity bool = false

@description('Flag indicating whether to deploy an application')
param deployApplication bool = false

@description('The image path of the application')
param appImagePath string = ''

@description('The number of application replicas to deploy')
param appReplicas int = 2

param guidValue string = take(replace(newGuid(), '-', ''), 6)

var const_appGatewaySSLCertOptionHaveCert = 'haveCert'
var const_appGatewaySSLCertOptionHaveKeyVault = 'haveKeyVault'
var const_appFrontendTlsSecretName = format('secret{0}', guidValue)
var const_appImage = format('{0}:{1}', const_appImageName, const_appImageTag)
var const_appImageName = format('image{0}', guidValue)
var const_appImagePath = (empty(appImagePath) ? 'NA' : ((const_appImagePathLen == 1) ? format('docker.io/library/{0}', appImagePath) : ((const_appImagePathLen == 2) ? format('docker.io/{0}', appImagePath) : appImagePath)))
var const_appImagePathLen = length(split(appImagePath, '/'))
var const_appImageTag = '1.0.0'
var const_appName = format('app{0}', guidValue)
var const_appProjName = 'default'
var const_arguments = format('{0} {1} {2} {3} {4} {5} {6} {7} {8}', const_clusterRGName, name_clusterName, name_acrName, deployApplication, const_appImagePath, const_appName, const_appProjName, const_appImage, appReplicas)
var const_availabilityZones = [
  '1'
  '2'
  '3'
]
var const_azureSubjectName = format('{0}.{1}.{2}', name_dnsNameforApplicationGateway, location, 'cloudapp.azure.com')
var const_clusterRGName = (createCluster ? resourceGroup().name : clusterRGName)
var const_cmdToGetAcrLoginServer = format('az acr show -n {0} --query loginServer -o tsv', name_acrName)
var const_regionsSupportAvailabilityZones = [
  'australiaeast'
  'brazilsouth'
  'canadacentral'
  'centralindia'
  'centralus'
  'eastasia'
  'eastus'
  'eastus2'
  'francecentral'
  'germanywestcentral'
  'japaneast'
  'koreacentral'
  'northeurope'
  'norwayeast'
  'southeastasia'
  'southcentralus'
  'swedencentral'
  'uksouth'
  'usgovvirginia'
  'westeurope'
  'westus2'
  'westus3'
]
var const_scriptLocation = uri(_artifactsLocation, 'scripts/')
var name_acrName = createACR ? format('acr{0}', guidValue) : acrName
var name_appGatewayPublicIPAddressName = format('{0}{1}', appGatewayPublicIPAddressName, guidValue)
var name_clusterName = createCluster ? format('cluster{0}', guidValue) : clusterName
var name_dnsNameforApplicationGateway = format('{0}{1}', dnsNameforApplicationGateway, guidValue)
var name_keyVaultName = format('keyvault{0}', guidValue)
var name_prefilghtDsName = format('preflightds{0}', guidValue)
var name_primaryDsName = format('primaryds{0}', guidValue)

module partnerCenterPid './modules/_pids/_empty.bicep' = {
  name: 'pid-68a0b448-a573-4012-ab25-d5dc9842063e-partnercenter'
  params: {}
}

module aksStartPid './modules/_pids/_empty.bicep' = {
  name: '628cae16-c133-5a2e-ae93-2b44748012fe'
  params: {}
}

resource preflightDsDeployment 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name_prefilghtDsName
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    primaryScriptUri: uri(const_scriptLocation, format('preflight.sh{0}', _artifactsLocationSasToken))
    environmentVariables: [
      {
        name: 'ENABLE_APPLICATION_GATEWAY_INGRESS_CONTROLLER'
        value: string(enableAppGWIngress)
      }
      {
        name: 'APPLICATION_GATEWAY_CERTIFICATE_OPTION'
        value: appGatewayCertificateOption
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_NAME'
        value: keyVaultName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_RESOURCEGROUP'
        value: keyVaultResourceGroup
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_FRONTEND_CERT_DATA_SECRET_NAME'
        value: keyVaultSSLCertDataSecretName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_FRONTEND_CERT_PASSWORD_SECRET_NAME'
        value: keyVaultSSLCertPasswordSecretName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_FRONTEND_CERT_DATA'
        secureValue: appGatewaySSLCertData
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_FRONTEND_CERT_PASSWORD'
        secureValue: appGatewaySSLCertPassword
      }
      {
        name: 'BASE64_FOR_SERVICE_PRINCIPAL'
        secureValue: servicePrincipal
      }
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource acrDeployment 'Microsoft.ContainerRegistry/registries@2021-09-01' = if (createACR) {
  name: name_acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  dependsOn: [
    preflightDsDeployment
  ]
}

resource clusterDeployment 'Microsoft.ContainerService/managedClusters@2021-02-01' = if (createCluster) {
  name: name_clusterName
  location: location
  properties: {
    enableRBAC: true
    dnsPrefix: format('{0}-dns', name_clusterName)
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        enableAutoScaling: true
        minCount: minCount
        maxCount: maxCount
        count: minCount
        vmSize: vmSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: (contains(const_regionsSupportAvailabilityZones, location) ? const_availabilityZones : null)
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'kubenet'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    acrDeployment
  ]
}

module appgwStartPid './modules/_pids/_empty.bicep' = if (enableAppGWIngress) {
  name: '43c417c4-4f5a-555e-a9ba-b2d01d88de1f'
  params: {}
  dependsOn: [
    clusterDeployment
  ]
}

// Workaround arm-ttk test "Parameter Types Should Be Consistent"
var _useExistingAppGatewaySSLCertificate = appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveCert
module appgwSecretDeployment 'modules/_azure-resoruces/_keyvaultForGateway.bicep' = if (enableAppGWIngress && (appGatewayCertificateOption != const_appGatewaySSLCertOptionHaveKeyVault)) {
  name: 'appgateway-certificates-secrets-deployment'
  params: {
    certificateDataValue: appGatewaySSLCertData
    certificatePasswordValue: appGatewaySSLCertPassword
    identity: identity
    location: location
    sku: keyVaultSku
    subjectName: format('CN={0}', const_azureSubjectName)
    useExistingAppGatewaySSLCertificate: _useExistingAppGatewaySSLCertificate
    keyVaultName: name_keyVaultName
  }
  dependsOn: [
    appgwStartPid
  ]
}

// get key vault object in a resource group
resource existingKeyvault 'Microsoft.KeyVault/vaults@2021-10-01' existing = if (enableAppGWIngress) {
  name: (!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultName : appgwSecretDeployment.outputs.keyVaultName
  scope: resourceGroup(appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault ? keyVaultResourceGroup : resourceGroup().name)
}

module appgwDeployment 'modules/_azure-resoruces/_appgateway.bicep' = if (enableAppGWIngress) {
  name: 'app-gateway-deployment'
  params: {
    dnsNameforApplicationGateway: name_dnsNameforApplicationGateway
    gatewayPublicIPAddressName: name_appGatewayPublicIPAddressName
    nameSuffix: guidValue
    location: location
  }
  dependsOn: [
    appgwStartPid
  ]
}

// Workaround arm-ttk test "Parameter Types Should Be Consistent"
var _enableAppGWIngress = enableAppGWIngress
module networkingDeployment 'modules/_deployment-scripts/_ds-create-agic.bicep' = if (enableAppGWIngress) {
  name: 'networking-deployment'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: location

    identity: identity

    appgwCertificateOption: appGatewayCertificateOption
    appgwFrontendSSLCertData: existingKeyvault.getSecret((!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultSSLCertDataSecretName : appgwSecretDeployment.outputs.sslCertDataSecretName)
    appgwFrontendSSLCertPsw: existingKeyvault.getSecret((!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultSSLCertPasswordSecretName : appgwSecretDeployment.outputs.sslCertPwdSecretName)

    appgwName: _enableAppGWIngress ? appgwDeployment.outputs.appGatewayName : ''
    appgwAlias: _enableAppGWIngress ? appgwDeployment.outputs.appGatewayAlias : ''
    appgwVNetName: _enableAppGWIngress ? appgwDeployment.outputs.vnetName : ''
    servicePrincipal: servicePrincipal

    aksClusterRGName: const_clusterRGName
    aksClusterName: name_clusterName
    appFrontendTlsSecretName: const_appFrontendTlsSecretName
    appProjName: const_appProjName
  }
  dependsOn: [
    appgwSecretDeployment
    appgwDeployment
  ]
}

module appgwEndPid './modules/_pids/_empty.bicep' = if (enableAppGWIngress) {
  name: 'dfa75d32-05de-5635-9833-b004cabcd378'
  params: {}
  dependsOn: [
    networkingDeployment
  ]
}

resource primaryDsDeployment 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name_primaryDsName
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    arguments: const_arguments
    primaryScriptUri: uri(const_scriptLocation, format('install.sh{0}', _artifactsLocationSasToken))
    supportingScriptUris: [
      uri(const_scriptLocation, format('open-liberty-application.yaml.template{0}', _artifactsLocationSasToken))
      uri(const_scriptLocation, format('open-liberty-application-agic.yaml.template{0}', _artifactsLocationSasToken))
    ]
    environmentVariables: [
      {
        name: 'ENABLE_APP_GW_INGRESS'
        value: string(enableAppGWIngress)
      }
      {
        name: 'APP_FRONTEND_TLS_SECRET_NAME'
        value: string(const_appFrontendTlsSecretName)
      }
      {
        name: 'ENABLE_COOKIE_BASED_AFFINITY'
        value: string(enableCookieBasedAffinity)
      }
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    clusterDeployment
    appgwEndPid
  ]
}

module aksEndPid './modules/_pids/_empty.bicep' = {
  name: '59f5f6da-0a6d-587d-b23c-177108cd8bbf'
  params: {}
  dependsOn: [
    primaryDsDeployment
  ]
}

output appHttpEndpoint string = deployApplication ? (enableAppGWIngress ? appgwDeployment.outputs.appGatewayURL : primaryDsDeployment.properties.outputs.appEndpoint ) : ''
output appHttpsEndoint string = deployApplication && enableAppGWIngress ? appgwDeployment.outputs.appGatewaySecuredURL : ''
output clusterName string = name_clusterName
output clusterRGName string = const_clusterRGName
output acrName string = name_acrName
output cmdToGetAcrLoginServer string = const_cmdToGetAcrLoginServer
output appNamespaceName string = const_appProjName
output appName string = deployApplication ? const_appName : ''
output appImage string = deployApplication ? const_appImage : ''
output cmdToConnectToCluster string = format('az aks get-credentials -g {0} -n {1}', const_clusterRGName, name_clusterName)
output cmdToGetAppInstance string = deployApplication ? format('kubectl get openlibertyapplication {0}', const_appName) : ''
output cmdToGetAppDeployment string = deployApplication ? format('kubectl get deployment {0}', const_appName) : ''
output cmdToGetAppPods string = deployApplication ? 'kubectl get pod' : ''
output cmdToGetAppService string = deployApplication ? format('kubectl get service {0}', const_appName) : ''
output cmdToLoginInRegistry string = format('az acr login -n {0}', name_acrName)
output cmdToPullImageFromRegistry string = deployApplication ? format('docker pull $({0})/{1}', const_cmdToGetAcrLoginServer, const_appImage) : ''
output cmdToTagImageWithRegistry string = format('docker tag <source-image-path> $({0})/<target-image-name:tag>', const_cmdToGetAcrLoginServer)
output cmdToPushImageToRegistry string = format('docker push $({0})/<target-image-name:tag>', const_cmdToGetAcrLoginServer)
output appDeploymentYaml string = deployApplication? format('echo "{0}" | base64 -d', primaryDsDeployment.properties.outputs.appDeploymentYaml) : ''
output appDeploymentTemplateYaml string =  !deployApplication ? format('echo "{0}" | base64 -d', primaryDsDeployment.properties.outputs.appDeploymentYaml) : ''
output cmdToUpdateOrCreateApplication string = 'kubectl apply -f <application-yaml-file-path>'