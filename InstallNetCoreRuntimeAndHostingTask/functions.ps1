function Download-DotNetCoreInstaller([string]$dotNetVersion, [bool]$useProxy, [string]$proxyServerAddress, [string]$outputFilePath)
{
    $fileName = "dotnet-hosting-win.exe"
    $releasesJSONURL = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/" + $dotNetVersion + "/releases.json"

    $webClient = New-Object System.Net.WebClient
    if ($useProxy -eq $true)
    {
        if (($null -eq $proxyServerAddress) -or ($proxyServerAddress -eq ""))
        {
            Write-Host "##vso[task.logissue type=error;]Proxy server address was not specified"
            [Environment]::Exit(1)
        }
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
    $outputFolder = Split-Path $outputFilePath
    if (-not(Test-Path $outputFolder))
    {
        New-Item -Path $outputFolder -ItemType Directory | Out-Null
    }


    # Download installer
    Write-Host Downloading $file.name from: $file.url
    $webClient.DownloadFile($file.url, $outputFilePath)
    Write-Host Downloaded $file.name to: $outputFilePath

    return $outputFilePath
}