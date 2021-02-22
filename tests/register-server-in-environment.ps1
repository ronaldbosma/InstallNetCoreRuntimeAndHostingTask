<#
    .SYNOPSIS
    Register server in Azure Piplines Environment.

    .DESCRIPTION
    Downloads and installs agent on this server and then registers the server in an Azure Pipelines Environment.

    .PARAMETER OrganizationUrl
    URL of the server. For example: https://myaccount.visualstudio.com or http://onprem:8080/tfs.

    .PARAMETER TeamProject
    Name of the team project. For example myProject.

    .PARAMETER Environment
    Name of the environment. For example myEnvironment.

    .PARAMETER Token
    Personal Access Token. The token needs the scope 'Environment (Read & manage)'.

    .PARAMETER Tags
    Optional comma separated list of tags to add to the server. For example: "web, sql".

    .EXAMPLE
    PS> .\register-server-in-environment.ps1 -OrganizationUrl https://myaccount.visualstudio.com -TeamProject myProject -Environment myEnvironment -Token myToken

    .EXAMPLE
    PS> .\register-server-in-environment.ps1 -OrganizationUrl https://myaccount.visualstudio.com -TeamProject myProject -Environment myEnvironment -Token myToken -Tags "web, sql"
#>
param (
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$TeamProject,
    [Parameter(Mandatory)][string]$Environment,
    [Parameter(Mandatory)][string]$Token,
    [string]$Tags
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
    mkdir $env:SystemDrive\'azagent'
};

cd $env:SystemDrive\'azagent';

# Create a unique A* folder for the agent using i as the index
for($i=1; $i -lt 100; $i++)
{
    $destFolder="A"+$i.ToString();
    if(-NOT (Test-Path ($destFolder)))
    {
        mkdir $destFolder;
        cd $destFolder;
        break;
    }
};

$agentZip="$PWD\agent.zip";

# Configure the web client used to download the zip file with the agent
$DefaultProxy=[System.Net.WebRequest]::DefaultWebProxy;
$securityProtocol=@();
$securityProtocol+=[Net.ServicePointManager]::SecurityProtocol;
$securityProtocol+=[Net.SecurityProtocolType]::Tls12;
[Net.ServicePointManager]::SecurityProtocol=$securityProtocol;
$WebClient=New-Object Net.WebClient; 
$Uri='https://vstsagentpackage.azureedge.net/agent/2.181.2/vsts-agent-win-x64-2.181.2.zip';
if($DefaultProxy -and (-not $DefaultProxy.IsBypassed($Uri)))
{
    $WebClient.Proxy= New-Object Net.WebProxy($DefaultProxy.GetProxy($Uri).OriginalString, $True);
};

# Download the zip file with the agent
$WebClient.DownloadFile($Uri, $agentZip);

# Extract the zip file
Add-Type -AssemblyName System.IO.Compression.FileSystem;
[System.IO.Compression.ZipFile]::ExtractToDirectory( $agentZip, "$PWD");

# Register the agent in the environment
if ([string]::IsNullOrWhiteSpace($Tags))
{
    .\config.cmd --unattended --environment --environmentname $Environment --agent $env:COMPUTERNAME --runasservice --work '_work' --url $OrganizationUrl --projectname $TeamProject --auth PAT --token $Token;
}
else
{
    .\config.cmd --unattended --environment --environmentname $Environment --agent $env:COMPUTERNAME --runasservice --work '_work' --url $OrganizationUrl --projectname $TeamProject --auth PAT --token $Token --addvirtualmachineresourcetags --virtualmachineresourcetags "$($Tags)";
}

# Remove the zip file
Remove-Item $agentZip;