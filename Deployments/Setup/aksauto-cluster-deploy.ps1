param([Parameter(Mandatory=$true)] [string] $mode)

$location = "eastus"
$resourceGroup = "aks-workshop-rg"
$spIdName = "aks-workshop-sp-id"
$spSecretName = "aks-workshop-sp-secret"
$keyVaultName = "aks-workshop-kv"
$aksVNetName = "aks-workshop-vnet"
$aksSubnetName = "aks-workshop-subnet"
$cluster = "aks-workshop-cluster"
$version = "1.14.8"
$addons = "monitoring"
$nodeCount = 3
$vmSetType = "VirtualMachineScaleSets"
$minNodeCount = 1
$maxNodeCount = 60
$maxPods = 50
$nodeVMSize = "Standard_DS2_v2"
$networkPlugin = "azure"
$networkPolicy = "azure"
$nodePoolName = "akswkpool"
$nodeResourceGroup = "aks-workshop-node-rg"
$aadServerAppID = "cd6c670a-b542-4e9d-a957-9f6e941c790e"
$aadServerAppSecret = "Fy4K25T8cf]gGIPjNa?SPD@zQnMeTpU@"
$aadClientAppID = "9601340e-735e-4294-84da-44bfe43c85a1"
$aadTenantID = "bbe9b0ad-f1c1-4242-87f9-f22d7621beea"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksWorkshopVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if (!$aksWorkshopVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksWorkshopSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksWorkshopVnet
if (!$aksWorkshopSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    az aks create --name $cluster --resource-group $resourceGroup `
    --node-resource-group $nodeResourceGroup `
    --kubernetes-version $version --enable-addons $addons --location $location `
    --vnet-subnet-id $aksWorkshopSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID `
    --generate-ssh-keys
    
}
elseif ($mode -eq "update")
{

    # az aks nodepool update --cluster-name $cluster --resource-group $resourceGroup `
    # --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    # --name $nodePoolName

    az aks update-credentials --name $cluster --resource-group $resourceGroup `
    --reset-aad `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID `

    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $cluster --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster done"

