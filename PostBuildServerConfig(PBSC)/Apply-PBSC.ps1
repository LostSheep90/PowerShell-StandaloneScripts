<#

.Synopsis

.Description
Config File Naming Convention

.NOTES
Written by Jeremy Felpel
GitHub: jfelpel

.LINK
https://github.com/jfelpel/

.Example

#>

Param(
	# [parameter(Mandatory=$true)]
	# [ValidateScript({
    #     if (Test-Path $_ -PathType 'Container') {
    #         $true
    #     }
    #     else {
    #         Throw "$_ is not a valid root path. Please enter a path that is accessible from this location and by the logged in user."
    #     }
    # })]
	# [String]
	# $ConfigDirectoryPath
	[parameter(Mandatory=$true)]
	[String]
	$XMLConfigFilePath
)

#Set Config File Path Variables
[xml]$XMLConfigFile = Get-Content $XMLConfigFilePath

<# Move AD Computer object to correct AD Group
	- Check the location of the servers AD object
		- If not in the correct location, move the server object
#>
$TargetOU = $XMLConfigFile.PBSC_Config.ServerADOU.name
$Hostname = $env:computername
$Computer = Get-ADComputer -Filter {name -eq $Hostname} -Properties *
if ($Computer.DistinguishedName -ne "CN=$Hostname,$TargetOU") {
	Write-Host "Move Computer Object"
}elseif ($Computer.DistinguishedName -eq "CN=$Hostname,$TargetOU") {
	Write-Host "Leave Computer Object in place."
}

<# Local Group Changes (what to add to which local group)
	- foreach group, add specified users
#>
foreach ($LocalGroup in $XMLConfigFile.PBSC_Config.LocalGroupChanges.localgroup) {
	$LocalGroup.name
	foreach ($ItemtoAdd in $LocalGroup.AddItem.name) {
		$ItemtoAdd
	}
}

<# Share Creation (share name and location, share permissions, security permissions)
	- Check if directory exists
		- If not, create it
	- Create Fileshare, permissions while creating
	- add items to NTFS ACL
#>
foreach ($FileShare in $XMLConfigFile.PBSC_Config.NetworkFileShares.FileShare) {
	$FileShare.name
	$FileShare.path
	foreach ($SharePermission in $Fileshare.SharePermissions.additem) {
		$SharePermission.name
		$SharePermission.permissionlevel	
	}
	foreach ($ACLChange in $FileShare.ACLChanges.additem) {
		$ACLChange.name
		$ACLChange.PermissionLevel		
	}
}

<# Config Changes
	- Unused portion - planned for future use
#>