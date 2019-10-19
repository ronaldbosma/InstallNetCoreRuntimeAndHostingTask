  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    . "$PSScriptRoot\functions.ps1"

    $dotNetVersion = Get-VstsInput -Name version -Require
    $useProxy = Get-VstsInput -Name useProxy -Require
    $proxyServerAddress = Get-VstsInput -Name proxyServerAddress -Require

    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"
    $workingDirectory = Join-Path $workingDirectory $dotNetVersion
    $outputFilePath = Join-Path $workingDirectory "dotnet-hosting-win.exe"

    $installerFilePath = Download-DotNetCoreInstaller -dotNetVersion $dotNetVersion -useProxy $useProxy -proxyServerAddress $proxyServerAddress -outputFilePath $outputFilePath

    
    $norestart = Get-VstsInput -Name norestart -Require

    $installerFolder = Split-Path $installerFilePath -Parent
    $fileName = Split-Path $installerFilePath -Leaf

    # Create log folder
    $logFolder = Join-Path $installerFolder "logs"
    $logFilePath = Join-Path $logFolder "$fileName.log"
    New-Item -Path $logFolder -ItemType Directory | Out-Null


    # Execute installer
    $installationArguments = "/passive /log $logFilePath"
    if ($norestart)
    {
        $installationArguments += " /norestart"
    }
    Write-Host Execute $installerFilePath with the following arguments: $installationArguments
    Write-Host Executing installer. This could take a few minutes...
    $process = Start-Process -FilePath $installerFilePath -ArgumentList $installationArguments -Wait -PassThru
    Write-Host Installer completed with exitcode: $process.ExitCode


    ## Upload installation logs
    $logFiles = Get-ChildItem $logFolder -Filter *.log
    foreach ($logFile in $logFiles) {
        $logFilePath = $logFile.FullName
        Write-Host Upload installation log: $logFilePath
        Write-Host "##vso[task.uploadfile]$logFilePath"
    }


    # Exit with error if installation failed
    if ($process.ExitCode -ne 0) {
        $exitCode = $process.ExitCode
        Write-Host "##vso[task.logissue type=error;]Installation failed with code: $exitCode. See attached logs for more details."
        [Environment]::Exit(1)
    }
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}