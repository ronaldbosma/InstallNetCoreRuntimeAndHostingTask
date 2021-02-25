param (
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$AdminUserName,
    [Parameter(Mandatory)][string]$AdminPassword
)

$location = "westeurope"
$vmName = "win-server-2019"

$ErrorActionPreference="Stop";

Write-Host "Create resource group $ResourceGroup"
az group create --name $ResourceGroup --location $location

Write-Host "Provision virtual machine $vmName"
az vm create `
    --name $vmName `
    --image Win2019Datacenter `
    --admin-username $AdminUserName `
    --admin-password $AdminPassword `
    --resource-group $ResourceGroup `
    --location $location

# The \" in the --settings param is required locally. Question is if it's required when executing this script in the Azure CLI task.
Write-Host "Install IIS on virtual machine $vmName"
az vm extension set `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --vm-name $vmName `
    --resource-group $ResourceGroup `
    --settings '{\"commandToExecute\":\"powershell.exe Install-WindowsFeature -Name Web-Server\"}'


#az group delete --name $ResourceGroup --no-wait --yes