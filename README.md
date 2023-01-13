# Related Repositories

* [tWAS cluster on Azure VMs](https://github.com/WASdev/azure.websphere-traditional.cluster)
* [Base images used in tWAS cluster](https://github.com/WASdev/azure.websphere-traditional.image)
* [Liberty on ARO](https://github.com/WASdev/azure.liberty.aro)



# Deploy a Java application with Open Liberty or WebSphere Liberty on an Azure Kubernetes Service (AKS) cluster

## Prerequisites

1. You will need an Azure subscription. If you don't have one, you can get one for free for one year [here](https://azure.microsoft.com/free).
1. You need to have either an **Owner** role or **Contributor** and **User Access Administrator** roles in the subscription.
1. Install a Java SE implementation (for example, [AdoptOpenJDK OpenJDK 8 LTS/OpenJ9](https://adoptopenjdk.net/?variant=openjdk8&jvmVariant=openj9)).
1. Install [Maven](https://maven.apache.org/download.cgi) 3.5.0 or higher.
1. Install [Docker](https://docs.docker.com/get-docker/) for your OS.
1. Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest&preserve-view=true) 2.0.75 or later.
1. Install [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install#linux).
1. Install [`jq`](https://stedolan.github.io/jq/download/)

## Steps of deployment

1. Checkout [azure-javaee-iaas](https://github.com/Azure/azure-javaee-iaas)
   1. Change to directory hosting the repo project & run `mvn clean install`
1. Checkout [arm-ttk](https://github.com/Azure/arm-ttk) under the specified parent directory
   1. Run `git checkout cf5c927eaf1f5652556e86a6b67816fc910d1b74` to checkout the verified version of `arm-ttk`
1. Checkout this repo under the same parent directory and change to directory hosting the repo project
1. Build the project by replacing all placeholder `${<place_holder>}` with valid values
   1. Create a new AKS cluster and a new Azure Container Registry (ACR) instance with Application Gateway Ingress Controller (AGIC) enabled:

      ```bash
      mvn -Dgit.repo=<repo_user> -Dgit.tag=<repo_tag> -DcreateCluster=true -DcreateACR=true -DdeployWLO=<true|false> -Dedition=<edition> -DproductEntitlementSource=<productEntitlementSource> -DdeployApplication=<true|false> -DappImagePath=<app-image-path> -DappReplicas=<number of replicas> -DenableAppGWIngress=true -DappgwUsePrivateIP=<true|false> -DappGatewayCertificateOption=generateCert -DenableCookieBasedAffinity=true -Dtest.args="-Test All" -Pbicep -Passembly -Ptemplate-validation-tests clean install
      ```

   1. Or use an existing AKS cluster and an existing ACR instance without AGIC:

      ```bash
      mvn -Dgit.repo=<repo_user> -Dgit.tag=<repo_tag> -DcreateCluster=false -DclusterName=<aks-cluster-name> -DclusterRGName=<cluster-group-name> -DcreateACR=false -DacrName=<acr-instance-name> -DacrRGName=<acr-group-name> -DdeployWLO=<true|false> -Dedition=<edition> -DproductEntitlementSource=<productEntitlementSource> -DdeployApplication=<true|false> -DappImagePath=<app-image-path> -DappReplicas=<number of replicas> -DenableAppGWIngress=false -DappgwUsePrivateIP=<true|false> -DappGatewayCertificateOption=generateCert -DenableCookieBasedAffinity=true -Dtest.args="-Test All" -Pbicep -Passembly -Ptemplate-validation-tests clean install
      ```

1. Change to `./target/cli` directory
1. Using `deploy.azcli` to deploy the application package to AKS cluster

   ```bash
   ./deploy.azcli -n <deploymentName> -g <resourceGroupName> -l <resourceGroupLocation> 
   ```

## After deployment

1. If you check the resource group `resourceGroupName` in [Azure portal](https://portal.azure.com/), you will see related resources created:
   1. A new AKS cluster if it's specified;
   1. A new ACR instance if it's specified;
   1. Two deployment script instances;
1. To visit the application home page if you chose to deploy a sample app:
   1. Open the resource group `resourceGroupName`;
   1. Navigate to "Deployments > `deploymentName` > Outputs";
   1. Copy value of property `appHttpEndpoint` > append context root defined in the 'server.xml' of your application if it's not equal to '/' > open it in the browser;
   1. If you enabled AGIC: copy value of property `appHttpsEndpoint` > append context root defined in the 'server.xml' of your application if it's not equal to '/' > open it in the browser;

## Deployment Description

The offer provisions the following Azure resources and a WebSphere Liberty Operator or Open Liberty Operator.

* Network resources
  * A virtual network and one subnet if user selects to deploy an Azure Application Gateway Ingress Controller (AGIC) and create a new virtual network.
  * A network security group if user selects to create a new virtual network.
  * An Application Gateway acting as Ingress controller for pods running in the AKS cluster if user selects to deploy AGIC, with the following configurables:
    * Create a new virtual network or bring user's own virtual network.
    * Options to provide TLS/SSL certificate (upload, identify an Azure Key Vault and generate a self-signed certificate).
    * Enable/disable cookie based affinity.
  * A public IP address assigned to the Azure Application Gateway if user selects to deploy AGIC.
* Storage resources
  * A container registry for storing images of application deployed to the AKS cluster if user selects to create a new one.
  * A keyvault for storing TLS/SSL certificate if user selects to deploy AGIC.
* Computing resources
  * An AKS cluster if user selects to create a new one, with the followings configurables:
    * VM size.
    * Minimum node count.
    * Maximum node count.
* Key software components
  * A WebSphere Liberty Operator or Open Liberty Operator installed and running on the AKS cluster, per user selection.
  * An WebSphere Liberty or Open Liberty application deployed and running on the AKS cluster, per user selection:
    * User can select to deploy an application or not.
    * User can deploy own application or a sample application.
    * User need to provide additional entitlement info to deploy the application if a WebSphere Liberty Operator (IBM supported) is deployed.
