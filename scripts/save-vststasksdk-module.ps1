New-Item "./InstallNetCoreRuntimeAndHostingTask/ps_modules" -ItemType Directory
$moduleVersion = (Find-Module VstsTaskSdk).Version.ToString()
Save-Module -Name VstsTaskSdk -LiteralPath "./InstallNetCoreRuntimeAndHostingTask/ps_modules"
# The PowerShell module is saved in a subfolder of VstsTaskSdk with the version as the folder name.
# The Azure Pipeline Task expects the module to be in the root VstsTaskSdk folder, so we move the files there.
$versionPath = Join-Path "./InstallNetCoreRuntimeAndHostingTask/ps_modules/VstsTaskSdk" $moduleVersion
if (Test-Path $versionPath -PathType Container)
{
  Move-Item "$versionPath/*" "./InstallNetCoreRuntimeAndHostingTask/ps_modules/VstsTaskSdk"
}