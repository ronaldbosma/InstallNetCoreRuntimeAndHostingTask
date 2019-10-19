  
[CmdletBinding()]
param() 
Trace-VstsEnteringInvocation $MyInvocation
try 
{
    $ErrorActionPreference = "Stop"

    Import-VstsLocStrings "$PSScriptRoot\Task.json"
    . "$PSScriptRoot\functions.ps1"

    $dotNetVersion = Get-VstsInput -Name version -Require
    $norestart = Get-VstsInput -Name norestart -AsBool -Require


    if ($norestart -eq $true) {
        write-host "norestart true"
    } else {
        write-host "norestart false"
    }
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}