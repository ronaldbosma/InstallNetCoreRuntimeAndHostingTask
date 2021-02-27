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
    Personal Access Token. The token needs the scopes 'Environment (Read & manage)' and 'Tokens (Read & manage)' in Azure DevOps.

    .EXAMPLE
    PS> .\delete-azure-vms.ps1 -Environment Environment -Token myToken
#>
param (
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$TeamProject,
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token
)

$environmentName = $Environment.Replace(".", "-"); # Azure DevOps doesn't allow . in the name of an environment so we replace it with a -
$ErrorActionPreference="Stop";

Write-Host "Log in to Azure DevOps organization $OrganizationUrl"
"$Token" | az devops login --organization $OrganizationUrl

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

Write-Host "Log out of Azure DevOps organization $OrganizationUrl"
az devops logout

Write-Host "Delete resource group $environmentName"
az group delete --name $environmentName --no-wait --yes