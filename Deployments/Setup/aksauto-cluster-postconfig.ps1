$resourceGroup = "aks-workshop-rg"
$clusterName = "aks-workshop-cluster"
$acrName = "akswkshpacr"
$aksVNetName = "aks-workshop-vnet"
$appgwSubnetName = "appgw-workshop-subnet"
$helmReleaseName = "internal-nginx"
$ingressNSName = "internal-nginx-ns"

$baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/AKSAutomate/Deployments"
$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"

$networkNames = "-vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/aksauto-appgw-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath $networkNames"

$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName"

$nginxNSCommand = "kubectl create namespace $ingressNSName"
$nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --namespace $ingressNSName -f $yamlFilePath/internal-ingress.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"

$acrDetails = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
$acrCredentials = Get-AzContainerRegistryCredential -ResourceGroupName $resourceGroup `
                    -Name $acrName

$dockerSecretName = "aksworkshop-secret"
$dockerServer = $acrDetails.LoginServer
$dockerUserName = $acrCredentials.Username
$dockerPassword = $acrCredentials.Password
                    
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"

# Switch Cluster context
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
Invoke-Expression -Command $dockerSecretCommand

# Create namespace for nginx
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
Invoke-Expression -Command $nginxILBCommand

# Docker Login command
Invoke-Expression -Command $dockerLoginCommand

# Install AppGW
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "Post config done"
