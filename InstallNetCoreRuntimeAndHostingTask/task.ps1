  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json" 

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -Require
    $useProxy = Get-VstsInput -Name useProxy -Require
    
    $fileName = "dotnet-hosting-win.exe"
    $releasesJSONURL = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/" + $dotNetVersion + "/releases.json"
    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"

    $webClient = new-Object System.Net.WebClient
    if ($useProxy) {
        $proxyServerAddress = Get-VstsInput -Name proxyServerAddress -Require
        Write-Host Proxy server $proxyServerAddress configured
        $webClient.Proxy = new-Object System.Net.WebProxy $proxyServerAddress
    }


    # Load releases.json
    Write-Host Load release data from: $releasesJSONURL
    $releases = $webClient.DownloadString($releasesJSONURL) | ConvertFrom-Json

    Write-Host Latest Release Version: $releases.'latest-release'
    Write-Host Latest Release Date: $releases.'latest-release-date'


    # Select the latest release
    $latestRelease = $releases.releases | Where-Object { ($_.'release-version' -eq $releases.'latest-release') -and ($_.'release-date' -eq $releases.'latest-release-date') }
        
    if ($latestRelease -eq $null)
    {
        Write-Host "##vso[task.logissue type=error;]No latest release found"
        [Environment]::Exit(1)
    }


    # Select the installer to download
    $file = $latestRelease.'aspnetcore-runtime'.files | Where-Object { $_.name -eq $fileName }
        
    if ($file -eq $null)
    {
        Write-Host "##vso[task.logissue type=error;]File $fileName not found in latest release"
        [Environment]::Exit(1)
    }


    # Create folder for installer
    $installerFolder = Join-Path $workingDirectory $releases.'latest-release'
    $installerFilePath = Join-Path $installerFolder $fileName

    if (Test-Path $installerFolder)
    {
        # Remove the folder to cleanup old logs etc.
        Remove-Item $installerFolder -Recurs -Force
    }
    $tmp = New-Item -Path $installerFolder -ItemType Directory


    # Download installer
    Write-Host Downloading $file.name from: $file.url
    $webClient.DownloadFile($file.url, $installerFilePath)
    Write-Host Downloaded $file.name to: $installerFilePath


    # Create log folder
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