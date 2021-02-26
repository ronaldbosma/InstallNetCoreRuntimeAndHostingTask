<#
    .SYNOPSIS
    Removes server from Azure Pipelines Environment.

    .DESCRIPTION
    Loops over all agent folders and
    - removes the agent from the Azure Pipelines Environment
    - remove the agent folder
    
    .PARAMETER Token
    Personal Access Token. The token needs the scope 'Environment (Read & manage)'.

    .EXAMPLE
    PS> .\unregister-server-from-environment.ps1 -Token myToken
#>
param (
    [Parameter(Mandatory)][string]$Token
)


$ErrorActionPreference="Stop";
If(-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent() ).IsInRole( [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    throw "Run command in an administrator PowerShell prompt"
};

If($PSVersionTable.PSVersion -lt (New-Object System.Version("3.0")))
{
    throw "The minimum version of Windows PowerShell that is required by the script (3.0) does not match the currently running version of Windows PowerShell."
};

If(-NOT (Test-Path $env:SystemDrive\'azagent'))
{
    Write-Host "Agent folder $($env:SystemDrive)\azagent not found"
    return;
};


cd $env:SystemDrive\'azagent';

$agentFolders = Get-ChildItem -Directory;
foreach ($agentFolder in $agentFolders)
{
    Write-Host "Unregister agent $agentFolder";
    & .\$agentFolder\config.cmd remove --unattended --auth PAT --token $Token;

    Write-Host "Remove agent folder $agentFolder";
    Remove-Item $agentFolder -Recurse
}



