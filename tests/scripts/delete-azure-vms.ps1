<#
    .SYNOPSIS
    Unregisters servers from Azure Pipelines environment and deletes resource groups.

    .DESCRIPTION
    Will retrieve all VMs from a resource group and unregister the server from any Azure Pipelines environment it's registered in.
    Then it will remove the resource group and all resources it contains.

    .PARAMETER Environment
    Name of the environment to delete. For example: MyResourceGroup.
    Is also the name of the correspondeing resource group that will be deleted.
    
    .PARAMETER Token
    Personal Access Token. The token needs the scope 'Environment (Read & manage)' in Azure DevOps.

    .EXAMPLE
    PS> .\delete-azure-vms.ps1 -Environment Environment -Token myToken
#>
param (
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token
)

$environmentName = $Environment.Replace(".", "-"); # Azure DevOps doesn't allow . in the name of an environment so we replace it with a -
# $unregisterServerScript = "https://raw.githubusercontent.com/ronaldbosma/InstallNetCoreRuntimeAndHostingTask/automated-test-pipeline/tests/scripts/unregister-server-from-environment.ps1";

$ErrorActionPreference="Stop";

Write-Host "Retrieve id of environment $environmentName from Azure DevOps team project $TeamProject"
$environmentId = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject `
    --org $OrganizationUrl `
    --api-version "6.0-preview" `
    --query "value[?name=='$environmentName'].id" `
    --output tsv

Write-Host "Delete environment $environmentName with id $environmentId from Azure DevOps team project $TeamProject"
az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject environmentId=$environmentId `
    --org $OrganizationUrl `
    --http-method DELETE `
    --api-version "6.0-preview"

# # Get all servers in the resource group
# $vms = az vm list --resource-group $environmentName | ConvertFrom-Json | Select-Object -ExpandProperty name;

# # Unregister each server from the Azure Pipelines environment
# foreach ($vm in $vms)
# {
#     Write-Host "Unregister $vm from environment";
#     $unregisterServerSettings="{`\`"fileUris`\`":[`\`"$unregisterServerScript`\`"], `\`"commandToExecute`\`":`\`"powershell.exe ./unregister-server-from-environment.ps1 -Token '$Token'`\`"}";
#     az vm extension set `
#         --name CustomScriptExtension `
#         --publisher Microsoft.Compute `
#         --vm-name $vm `
#         --resource-group $environmentName `
#         --settings $unregisterServerSettings;
# }

Write-Host "Delete resource group $environmentName"
az group delete --name $environmentName --no-wait --yes