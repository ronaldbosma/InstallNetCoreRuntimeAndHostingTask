$ErrorActionPreference="Stop";



# Retrieve list with releases for the Azure Pipelines agent
$releasesUrl = "https://api.github.com/repos/Microsoft/azure-pipelines-agent/releases"

$webClient1 = New-Object System.Net.WebClient
$webClient1.Headers.Add("user-agent", "azure pipeline");
$releases = $webClient1.DownloadString($releasesUrl) | ConvertFrom-Json

# Select the newest agent release
$latestAgentRelease = $releases | Sort-Object -Property published_at -Descending | Select-Object -First 1
$assetsUrl = $latestAgentRelease.assets[0].browser_download_url

# Get the agent download url from the agent release assets
$assets = $webClient1.DownloadString($assetsUrl) | ConvertFrom-Json
$downloadUrl = $assets | Where-Object { $_.platform -eq "win-x64"} | Select-Object -First 1 -Property downloadUrl



$downloadUrl
