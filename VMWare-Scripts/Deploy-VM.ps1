<#
.Synopsis
Deploys a VM based on some basic input from the user and some assumptions about the vmware environment.

.Description

.Notes
Written by Jeremy Felpel
GitHub: jfelpel

.Link
https://github.com/jfelpel/PowerShell-StandaloneScripts

.Example

#>

Param(
	[parameter(Mandatory=$true)]
	[String]
    $NewVMName,
    [parameter(Mandatory=$false)]
	[String]
    $Purpose = 'Test',
    [parameter(Mandatory=$true)]
	[String]
    $NewVMIP,
    [parameter(Mandatory=$true)]
	[String]
    $NewVMVLAN,
    [parameter(Mandatory=$false)]
	[String]
    $NewVMEnvironment = 'Test'
)

