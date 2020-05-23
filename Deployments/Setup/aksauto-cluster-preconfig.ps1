$resourceGroup = "aks-workshop-rg"
$spIdName = "aks-workshop-sp-id"
$spSecretName = "aks-workshop-sp-secret"
$acrName = "akswkshpacr"
$keyVaultName = "aks-workshop-kv"
$aksVNetName = "aks-workshop-vnet"
$aksSubnetName = "aks-workshop-subnet"
$appgwSubnetName = "appgw-workshop-subnet"
$vnetRole = "Network Contributor"
$certSecretName = "aks-appgw-secret"
$subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6"
$objectId = "890c52c5-d318-4185-a548-e07827190ff6"

$baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/AKSAutomate/Deployments"
$templatesFolderPath = $baseFolderPath + "/Templates"
$certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

$loginCommand = "az login"
$subscriptionCommand = "az account set -s $subscriptionId"

$networkNames = "-aksVNetName $aksVNetName -aksSubnetName $aksSubnetName -appgwSubnetName $appgwSubnetName"
$networkDeployCommand = "/Network/aksauto-network-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath $networkNames"

$acrDeployCommand = "/ACR/aksauto-acr-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/aksauto-keyvault-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -keyVaultName $keyVaultName -objectId $objectId"

# PS Login
Connect-AzAccount

# CLI Login
Invoke-Expression -Command $loginCommand

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$servicePrinciple = New-AzADServicePrincipal -SkipAssignment
if (!$servicePrinciple)
{

    Write-Host "Error creating Service Principal"
    return;

}

$secretBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrinciple.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secretBSTR)
Write-Host $servicePrinciple.DisplayName
Write-Host $servicePrinciple.Id
Write-Host $servicePrinciple.ApplicationId
Write-Host $secret

$spObjectId = ConvertTo-SecureString $servicePrinciple.ApplicationId `
-AsPlainText -Force

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force

$spObjectId = ConvertTo-SecureString -String $servicePrinciple.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName -SecretValue $spObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName `
-SecretValue $servicePrinciple.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $servicePrinciple.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}


