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

param _artifactsLocation string = deployment().properties.templateLink.uri
@secure()
param _artifactsLocationSasToken string = ''
param location string
param name string = ''
param identity object = {}
param enableAppGWIngress bool = false
param vnetForApplicationGateway object = {}
param appGatewayCertificateOption string = ''
param keyVaultName string = ''
param keyVaultResourceGroup string = ''
param keyVaultSSLCertDataSecretName string = ''
param keyVaultSSLCertPasswordSecretName string = ''
@secure()
param appGatewaySSLCertData string = ''
@secure()
param appGatewaySSLCertPassword string = ''
@secure()
param servicePrincipal string = ''

param utcValue string = utcNow()

var const_scriptLocation = uri(_artifactsLocation, 'scripts/')
var const_primaryScript = 'preflight.sh'

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    environmentVariables: [
      {
        name: 'ENABLE_APPLICATION_GATEWAY_INGRESS_CONTROLLER'
        value: string(enableAppGWIngress)
      }
      {
        name: 'VNET_FOR_APPLICATIONGATEWAY'
        value: string(vnetForApplicationGateway)
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
    primaryScriptUri: uri(const_scriptLocation, '${const_primaryScript}${_artifactsLocationSasToken}')

    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: utcValue
  }
}