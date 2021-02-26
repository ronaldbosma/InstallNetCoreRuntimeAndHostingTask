param (
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$AdminPassword,
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$TeamProject,
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token,
    [string]$Tags
)

$location = "westeurope";
$vmName = "vm-$(Get-Date -UFormat %s)"; # Max length for server name is 15 characters
$registerServerScript = "https://raw.githubusercontent.com/ronaldbosma/InstallNetCoreRuntimeAndHostingTask/automated-test-pipeline/tests/scripts/register-server-in-environment.ps1";

$ErrorActionPreference="Stop";

Write-Host "Create resource group $ResourceGroup";
az group create --name $ResourceGroup --location $location;

Write-Host "Provision virtual machine $vmName";
az vm create `
    --name $vmName `
    --image Win2019Datacenter `
    --admin-password $AdminPassword `
    --resource-group $ResourceGroup `
    --location $location;

Write-Host "Install IIS on virtual machine $vmName";
az vm extension set `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --vm-name $vmName `
    --resource-group $ResourceGroup `
    --settings '{\"commandToExecute\":\"powershell.exe Install-WindowsFeature -Name Web-Server -IncludeManagementTools\"}';

Write-Host "Add $vmName to environment $Environment in team project $TeamProject";
$registerServerSettings="{`\`"fileUris`\`":[`\`"$registerServerScript`\`"], `\`"commandToExecute`\`":`\`"powershell.exe ./register-server-in-environment.ps1 -OrganizationUrl '$OrganizationUrl' -TeamProject '$TeamProject' -Environment '$Environment' -Token '$Token' -Tags '$Tags'`\`"}";
az vm extension set `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --vm-name $vmName `
    --resource-group $ResourceGroup `
    --settings $registerServerSettings;


#az group delete --name $ResourceGroup --no-wait --yes;