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
