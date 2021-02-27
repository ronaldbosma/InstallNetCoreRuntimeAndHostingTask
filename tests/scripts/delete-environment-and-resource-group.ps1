<#
    .SYNOPSIS
    Delete Azure Pipelines environment and Azure resource group

    .DESCRIPTION
    Will delete the Azure Pipelines environment from Azure DevOps and the resource group from Azure.

    .PARAMETER Environment
    Name of the environment to delete. For example: myEnvironment.
    Is also the name of the corresponding resource group that will be deleted.
    
    .PARAMETER Token
    Personal Access Token. The token needs the scopes 'Environment (Read & manage)' and 'Tokens (Read & manage)' in Azure DevOps.

    .EXAMPLE
    PS> .\delete-environment-and-resource-group.ps1 -Environment myEnvironment -Token myToken
#>
param (
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$TeamProject,
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token
)

$ErrorActionPreference="Stop";

Write-Host "Log in to Azure DevOps organization $OrganizationUrl"
"$Token" | az devops login --organization $OrganizationUrl

Write-Host "Retrieve id of environment $Environment from Azure DevOps team project $TeamProject"
$environmentId = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject `
    --org $OrganizationUrl `
    --api-version "6.0-preview" `
    --query "value[?name=='$Environment'].id" `
    --output tsv

Write-Host "Delete environment $Environment with id $environmentId from Azure DevOps team project $TeamProject"
az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject environmentId=$environmentId `
    --org $OrganizationUrl `
    --http-method DELETE `
    --api-version "6.0-preview"

Write-Host "Log out of Azure DevOps organization $OrganizationUrl"
az devops logout

Write-Host "Delete resource group $Environment"
az group delete --name $Environment --no-wait --yes