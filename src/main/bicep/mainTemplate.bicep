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

@description('Flag indicating whether to deploy an application')
param deployApplication bool = false

@description('The image path of the application')
param appImagePath string = ''

@description('The number of application replicas to deploy')
param appReplicas int = 2

@secure()
param guidValue string = newGuid()

var const_appImage = format('{0}:{1}', const_appImageName, const_appImageTag)
var const_appImageName = format('image{0}', const_suffix)
var const_appImagePath = (empty(appImagePath) ? 'NA' : ((const_appImagePathLen == 1) ? format('docker.io/library/{0}', appImagePath) : ((const_appImagePathLen == 2) ? format('docker.io/{0}', appImagePath) : appImagePath)))
var const_appImagePathLen = length(split(appImagePath, '/'))
var const_appImageTag = '1.0.0'
var const_appName = format('app{0}', const_suffix)
var const_appProjName = 'default'
var const_arguments = format('{0} {1} {2} {3} {4} {5} {6} {7} {8}', const_clusterRGName, name_clusterName, name_acrName, deployApplication, const_appImagePath, const_appName, const_appProjName, const_appImage, appReplicas)
var const_availabilityZones = [
  '1'
  '2'
  '3'
]
var const_clusterRGName = (createCluster ? resourceGroup().name : clusterRGName)
var const_cmdToGetAcrLoginServer = 'az acr show -n ${name_acrName} --query loginServer -o tsv'
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
var const_suffix = take(replace(guidValue, '-', ''), 6)
var name_acrName = (createACR ? 'acr${const_suffix}' : acrName)
var name_clusterName = (createCluster ? 'cluster${const_suffix}' : clusterName)
var name_deploymentScriptName = 'script${const_suffix}'
var name_cpDeploymentScript = 'cpscript${const_suffix}'

module partnerCenterPid './modules/_pids/_empty.bicep' = {
  name: 'pid-68a0b448-a573-4012-ab25-d5dc9842063e-partnercenter'
  params: {}
}

module aksStartPid './modules/_pids/_empty.bicep' = {
  name: '628cae16-c133-5a2e-ae93-2b44748012fe'
  params: {}
}

resource checkPermissionDsDeployment 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name_cpDeploymentScript
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    primaryScriptUri: uri(const_scriptLocation, 'check-permission.sh${_artifactsLocationSasToken}')
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

resource acrDeployment 'Microsoft.ContainerRegistry/registries@2019-05-01' = if (createACR) {
  name: name_acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  dependsOn: [
    checkPermissionDsDeployment
  ]
}

resource clusterDeployment 'Microsoft.ContainerService/managedClusters@2021-02-01' = if (createCluster) {
  name: name_clusterName
  location: location
  properties: {
    enableRBAC: true
    dnsPrefix: '${name_clusterName}-dns'
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

resource primaryDsDeployment 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name_deploymentScriptName
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    arguments: const_arguments
    primaryScriptUri: uri(const_scriptLocation, 'install.sh${_artifactsLocationSasToken}')
    supportingScriptUris: [
      uri(const_scriptLocation, 'open-liberty-application.yaml.template${_artifactsLocationSasToken}')
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
  dependsOn: [
    clusterDeployment
  ]
}

module aksEndPid './modules/_pids/_empty.bicep' = {
  name: '59f5f6da-0a6d-587d-b23c-177108cd8bbf'
  params: {}
  dependsOn: [
    primaryDsDeployment
  ]
}

output appEndpoint string = deployApplication ? primaryDsDeployment.properties.outputs.appEndpoint : ''
output clusterName string = name_clusterName
output clusterRGName string = const_clusterRGName
output acrName string = name_acrName
output cmdToGetAcrLoginServer string = const_cmdToGetAcrLoginServer
output appNamespaceName string = const_appProjName
output appName string = deployApplication ? const_appName : ''
output appImage string = deployApplication ? const_appImage : ''
output cmdToConnectToCluster string = 'az aks get-credentials -g ${const_clusterRGName} -n ${name_clusterName}'
output cmdToGetAppInstance string = deployApplication ? 'kubectl get openlibertyapplication ${const_appName}' : ''
output cmdToGetAppDeployment string = deployApplication ? 'kubectl get deployment ${const_appName}' : ''
output cmdToGetAppPods string = deployApplication ? 'kubectl get pod' : ''
output cmdToGetAppService string = deployApplication ? 'kubectl get service ${const_appName}' : ''
output cmdToLoginInRegistry string = 'az acr login -n ${name_acrName}'
output cmdToPullImageFromRegistry string = deployApplication ? 'docker pull $(${const_cmdToGetAcrLoginServer})/${const_appImage}' : ''
output cmdToTagImageWithRegistry string = 'docker tag <source-image-path> $(${const_cmdToGetAcrLoginServer})/<target-image-name:tag>'
output cmdToPushImageToRegistry string = 'docker push $(${const_cmdToGetAcrLoginServer})/<target-image-name:tag>'
output appDeploymentYaml string = deployApplication? format('echo "{0}" | base64 -d', primaryDsDeployment.properties.outputs.appDeploymentYaml) : ''
output appDeploymentTemplateYaml string =  !deployApplication ? format('echo "{0}" | base64 -d', primaryDsDeployment.properties.outputs.appDeploymentYaml) : ''
output cmdToUpdateOrCreateApplication string = 'kubectl apply -f <application-yaml-file-path>'
