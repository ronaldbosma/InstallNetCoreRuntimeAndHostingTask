  
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
    $useProxy = Get-VstsInput -Name useProxy -Require


    if ($norestart -eq $true) {
        write-host "norestart true"
    } else {
        write-host "norestart false"
    }
    
    if ($useProxy -eq $true) {
        write-host "useProxy true"
    } else {
        write-host "useProxy false"
    }
    
    if ($useProxy -eq 'true') {
        write-host "useProxy string true"
    } elseif ($useProxy -eq 'false') {
        write-host "useProxy string false"
    } else {
        write-host "useProxy string else"
    }
}
finally
{
	Trace-VstsLeavingInvocation $MyInvocation
}