  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json" 

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -Require

    $fileName = "dotnet-hosting-win.exe"
    $releasesJSONURL = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/" + $dotNetVersion + "/releases.json"
    $webClient = new-Object System.Net.WebClient

    # Load releases.json
    Write-Host Load release data from: $releasesJSONURL
    $releases = $webClient.DownloadString($releasesJSONURL) | ConvertFrom-Json
    
    Write-Host Latest Release Version: $releases.'latest-release'
    Write-Host Latest Release Date: $releases.'latest-release-date'


    # Select the latest release
    $latestRelease = $releases.releases | Where-Object { ($_.'release-version' -eq $releases.'latest-release') -and ($_.'release-date' -eq $releases.'latest-release-date') }
        
    if ($latestRelease -eq $null)
    {
        throw "No latest release found"
    }


    # Select the installer to download
    $file = $latestRelease.'aspnetcore-runtime'.files | Where-Object { $_.name -eq $fileName }
        
    if ($file -eq $null)
    {
        throw "File $fileName not found in latest release"
    }

    $installerFolder = Join-Path "$(System.DefaultWorkingDirectory)" $releases.'latest-release'
    $installerFilePath = Join-Path $installerFolder $fileName
    $tmp = New-Item -Path $installerFolder -ItemType Directory

    # Download installer
    Write-Host Downloading $file.name from: $file.url
    $webClient.DownloadFile($file.url, $installerFilePath)
    Write-Host Downloaded $file.name to: $installerFilePath


    $logFolder = Join-Path $installerFolder "logs"
    $logFilePath = Join-Path $logFolder "$fileName.log"
    $tmp = New-Item -Path $logFolder -ItemType Directory

    # Execute installer
    $installationArguments = "/passive /log $logFilePath"
    if ($norestart)
    {
        $installationArguments += " /norestart"
    }
    Write-Host Execute $installerFilePath with the following arguments: $installationArguments
    Write-Host Executing...
    Start-Process -FilePath $installerFilePath -ArgumentList $installationArguments -Wait
    Write-Host Installation completed
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}