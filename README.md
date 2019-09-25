# Install .NET Core Runtime & Hosting Task

Azure DevOps pipeline task that installs/updates the .NET Core runtime and hosting bundle.

## Supported .NET Core versions
- 2.1
- 2.2
- 3.0

## Arguments

| Name | Description |
|-|-|
| Version | Version of .NET Core to install. |
| No Restart | If true, the `/norestart` argument will be passed to the installer to suppress any attempts to restart. |

## How to use

1. Install the [Install .NET Core Runtime & Hosting Bundle](https://marketplace.visualstudio.com/items?itemName=rbosma.InstallNetCoreRuntimeAndHosting) extension from the Marketplace in your Azure DevOps organization.
2. Create a new release pipeline.
3. Add a deployment group job.
4. Add the `Install .NET Core Runtime & Hosting Bundle` task to the deployment group job.
5. Configure the version you want to install.

## How it works

This task wraps a PowerShell script that:
1. retrieves the latest available .NET Core version from the appropriate `releases.json`, like https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/3.0/releases.json
2. looks in the `releases.json` for the download URL of the .NET Core Runtime & Hosting bundle installer (`dotnet-hosting-win.exe`)
3. downloads the installer
4. executes the installer
5. uploads any logs created by the installer

