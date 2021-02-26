param (
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$Token
)


$unregisterServerScript = "https://raw.githubusercontent.com/ronaldbosma/InstallNetCoreRuntimeAndHostingTask/automated-test-pipeline/tests/scripts/unregister-server-from-environment.ps1";

$ErrorActionPreference="Stop";

# Get all servers in the resource group
$vms = az vm list --resource-group $ResourceGroup | ConvertFrom-Json | Select-Object -ExpandProperty name;

# Unregister each server from the Azure Pipelines environment
foreach ($vm in $vms)
{
    Write-Host "Unregister $vm from environment";
    $unregisterServerSettings="{`\`"fileUris`\`":[`\`"$unregisterServerScript`\`"], `\`"commandToExecute`\`":`\`"powershell.exe ./unregister-server-from-environment.ps1 -Token '$Token'`\`"}";

    az vm extension set `
        --name CustomScriptExtension `
        --publisher Microsoft.Compute `
        --vm-name $vm `
        --resource-group $ResourceGroup `
        --settings $unregisterServerSettings;
}

# Delete the resource group
az group delete --name $ResourceGroup --no-wait --yes