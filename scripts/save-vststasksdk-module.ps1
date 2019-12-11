Remove-Item "InstallNetCoreRuntimeAndHostingTask" -Force -Confirm



$psModulesDirectory = New-Item "./InstallNetCoreRuntimeAndHostingTask/ps_modules" -ItemType Directory

Write-Host $psModulesDirectory.FullName

Save-Module -Name VstsTaskSdk -LiteralPath $psModulesDirectory.FullName

# The PowerShell module is saved in a subfolder of VstsTaskSdk with the version as the folder name.
# The Azure Pipeline Task expects the module to be in the root VstsTaskSdk folder, so we move the files there.

$moduleVersion = (Find-Module VstsTaskSdk).Version.ToString()
$versionPath = Join-Path $psModulesDirectory.FullName "VstsTaskSdk" $moduleVersion

if (Test-Path $versionPath -PathType Container)
{
    Move-Item "$versionPath/*" "./InstallNetCoreRuntimeAndHostingTask/ps_modules/VstsTaskSdk"
}