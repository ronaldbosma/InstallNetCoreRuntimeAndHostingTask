  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    . "$PSScriptRoot\functions.ps1"

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -Require -AsBool
    $useProxy = Get-VstsInput -Name useProxy -Require -AsBool
    $proxyServerAddress = ""
    if ($useProxy -eq $true) {
        $proxyServerAddress = Get-VstsInput -Name proxyServerAddress -Require
    }

    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"
    $workingDirectory = Join-Path $workingDirectory $dotNetVersion
    $outputFilePath = Join-Path $workingDirectory "dotnet-hosting-win.exe"

    $installerFilePath = Get-DotNetCoreInstaller -dotNetVersion $dotNetVersion -useProxy $useProxy -proxyServerAddress $proxyServerAddress -outputFilePath $outputFilePath
    Install-DotNetCore -installerFilePath $installerFilePath -norestart $norestart
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}