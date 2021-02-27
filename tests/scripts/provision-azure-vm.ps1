<#
    .SYNOPSIS
    Provision server and register it in Azure Pipelines environment.

    .DESCRIPTION
    Provisions a server in Azure and then registers the server in an Azure Pipelines environment.

    .PARAMETER AdminPassword
    Password of the administrator of the VM. For example: Adm!nP@ssw0rd.

    .PARAMETER OrganizationUrl
    URL of the organization. For example: https://myaccount.visualstudio.com or http://onprem:8080/tfs.

    .PARAMETER TeamProject
    Name of the team project. For example myProject.

    .PARAMETER Environment
    Name of the environment. For example myEnvironment.
    Will be used for the name of the Azure DevOps environment and Azure resource group.

    .PARAMETER Token
    Personal Access Token. The token needs the scope 'Environment (Read & manage)' in Azure DevOps.

    .PARAMETER Tags
    Optional comma separated list of tags to add to the server. For example: "web, sql".

    .EXAMPLE
    PS> .\provision-azure-vm.ps1 -AdminPassword Adm!nP@ssw0rd -OrganizationUrl https://myaccount.visualstudio.com -TeamProject myProject -Environment myEnvironment -Token myToken

    .EXAMPLE
    PS> .\provision-azure-vm.ps1 -AdminPassword Adm!nP@ssw0rd -OrganizationUrl https://myaccount.visualstudio.com -TeamProject myProject -Environment myEnvironment -Token myToken -Tags "web, sql"
#>
param (
    [Parameter(Mandatory)][string]$AdminPassword,
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$TeamProject,
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token,
    [string]$Tags
)

$environmentName = $Environment.Replace(".", "-"); # Azure DevOps doesn't allow . in the name of an environment so we replace it with a -
$location = "westeurope";
$vmName = "vm-$(Get-Date -UFormat %s)"; # Max length for server name is 15 characters
$registerServerScript = "https://raw.githubusercontent.com/ronaldbosma/InstallNetCoreRuntimeAndHostingTask/automated-test-pipeline/tests/scripts/register-server-in-environment.ps1";

$ErrorActionPreference="Stop";



# Provision Azure DevOps environment


Write-Host "Log in to Azure DevOps organization $OrganizationUrl"
"$Token" | az devops login --organization $OrganizationUrl


Write-Host "Create environment $environmentName in Azure DevOps team project $TeamProject"

$createEnvironmentBody = @{ name = $environmentName; description = "Provisioned environment $environmentName" };
$createEnvironmentFile = "create-environment-body.json";
Set-Content -Path $createEnvironmentFile -Value ($createEnvironmentBody | ConvertTo-Json);

$environment = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject `
    --org $OrganizationUrl `
    --http-method POST `
    --in-file $createEnvironmentFile `
    --api-version "6.0-preview";

Remove-Item $createEnvironmentFile -Force;


Write-Host "Log out of Azure DevOps organization $OrganizationUrl"
az devops logout



# Provision Azure virtual machine


Write-Host "Create resource group $environmentName";
az group create --name $environmentName --location $location;


Write-Host "Provision virtual machine $vmName";
az vm create `
    --name $vmName `
    --image Win2019Datacenter `
    --admin-password $AdminPassword `
    --resource-group $environmentName `
    --location $location;


Write-Host "Install IIS on virtual machine $vmName";
az vm extension set `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --vm-name $vmName `
    --resource-group $environmentName `
    --settings '{\"commandToExecute\":\"powershell.exe Install-WindowsFeature -Name Web-Server -IncludeManagementTools\"}';


    
# Register Azure virtual machine in Azure DevOps environment


Write-Host "Add $vmName to environment $environmentName in Azure DevOps team project $TeamProject";
$registerServerSettings="{`\`"fileUris`\`":[`\`"$registerServerScript`\`"], `\`"commandToExecute`\`":`\`"powershell.exe ./register-server-in-environment.ps1 -OrganizationUrl '$OrganizationUrl' -TeamProject '$TeamProject' -Environment '$environmentName' -Token '$Token' -Tags '$Tags'`\`"}";
az vm extension set `
    --name CustomScriptExtension `
    --publisher Microsoft.Compute `
    --vm-name $vmName `
    --resource-group $environmentName `
    --settings $registerServerSettings;
