  
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
    $installArguments = Get-VstsInput -Name installArguments

    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"
    $workingDirectory = Join-Path $workingDirectory $dotNetVersion
    $outputFilePath = Join-Path $workingDirectory "dotnet-hosting-win.exe"
    
      $version = dotNetVersion
      $installedSoftware = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*;
      
      $isRuntimeInstalled = ($installedSoftware | Where-Object { $_.DisplayName -match "Microsoft .NET (Core )?Runtime - $version.+" }) -ne $null
      if ($isRuntimeInstalled) {
        Write-Host "Microsoft .NET (Core) Runtime version $Version is installed"
      } else {
        Write-Host "Microsoft .NET (Core) Runtime version $version is not installed"
      }
      $isHostInstalled = ($installedSoftware | Where-Object { $_.DisplayName -match "Microsoft .NET (Core )?Host - $version.+" }) -ne $null
      if ($isHostInstalled) {
        Write-Host "Microsoft .NET (Core) Host version $Version is installed"
        [Environment]::Exit(1)
      } else {
        Write-Host "Microsoft .NET (Core) Host version $version is not installed"
      }

    $installerFilePath = Get-DotNetCoreInstaller $dotNetVersion $useProxy $proxyServerAddress $outputFilePath
    Install-DotNetCore $installerFilePath $norestart $iisReset $installArguments
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}
