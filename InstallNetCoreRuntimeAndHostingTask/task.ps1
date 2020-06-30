  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    . "$PSScriptRoot\functions.ps1"

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -AsBool -Require
    $useProxy = Get-VstsInput -Name useProxy -AsBool -Require
    $proxyServerAddress = ""
    if ($useProxy -eq $true) {
        $proxyServerAddress = Get-VstsInput -Name proxyServerAddress -Require
    }
    $iisReset = Get-VstsInput -Name iisReset -AsBool -Require
    $forceInstall = Get-VstsInput -Name forceInstall -AsBool -Require

    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"
    $workingDirectory = Join-Path $workingDirectory $dotNetVersion
    $outputFilePath = Join-Path $workingDirectory "dotnet-hosting-win.exe"

    $latestRelease = Get-DotNetLatestRelease $dotNetVersion $useProxy $proxyServerAddress

    if ($forceInstall) {
        Write-Host Bypassing check for existing installation
    }
    $shouldInstall = $force -or -not ((Test-DotNetCoreRuntimeIsInstalled $dotNetVersion) -and (Test-AspNetCoreModuleIsInstalled))

    if ($shouldInstall) {
        $installerFilePath = Get-DotNetCoreInstaller $latestRelease $useProxy $proxyServerAddress $outputFilePath
        Install-DotNetCore $installerFilePath $norestart $iisReset
    }
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}