function Download-DotNetCoreInstaller([string]$dotNetVersion, [bool]$useProxy, [string]$proxyServerAddress, [string]$outputFolder)
{

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -Require
    $useProxy = Get-VstsInput -Name useProxy -Require
    
    $fileName = "dotnet-hosting-win.exe"
    $releasesJSONURL = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/" + $dotNetVersion + "/releases.json"
    $workingDirectory = Get-VstsTaskVariable -Name "System.DefaultWorkingDirectory"

    $webClient = New-Object System.Net.WebClient
    if ($useProxy -eq $true) {
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
        
    if ($null -eq $latestRelease)
    {
        Write-Host "##vso[task.logissue type=error;]No latest release found"
        [Environment]::Exit(1)
    }


    # Select the installer to download
    $file = $latestRelease.'aspnetcore-runtime'.files | Where-Object { $_.name -eq $fileName }
        
    if ($null -eq $file)
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
}