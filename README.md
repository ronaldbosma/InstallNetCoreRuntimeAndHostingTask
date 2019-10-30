# Install .NET Core Runtime & Hosting Task

Azure DevOps pipeline task that downloads and installs/updates the latest .NET Core runtime and hosting bundle.

## Supported .NET Core versions
- 2.1
- 2.2
- 3.0

## YAML snippet
```yaml
# Install .NET Core Runtime & Hosting Bundle
# Install/update the .NET Core runtime and hosting bundle
- task: InstallNetCoreRuntimeAndHosting@0
  inputs:
    #version: '3.0' # Options: 2.1, 2.2, 3.0
    #norestart: false
    #useProxy: false
    #proxyServerAddress: # Required when useProyx == true
    #iisReset: true
```

## Arguments

| Name | Description |
|-|-|
| `version`<br />Version | Version of .NET Core to download and install.<br />Options: `2.1`, `2.2`, `3.0` |
| `useProxy`<br />Use a proxy server | Enabling this option will make it possible to specify a proxy server address that will be used to download the installer. |
| `proxyServerAddress`<br />Proxy server address | The URL of the proxy server to use when downloading the installer. Needs to include the port number.<br />Example: `http://proxy.example.com:80` |
| `norestart`<br />No Restart | Enabling this option will pass the `/norestart` argument to the installer to suppress any attempts to restart. |
| `iisReset`<br />Perform IIS reset | Enabling this option will reset IIS after installation.<br />The reset is recommended for all changes to take effect. |

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

