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
# $TargetOU = "CN=Computers,DC=donegalgroup,DC=com"
# $Hostname = $env:computername
$Hostname = 'JF-DIG-LAPTOP1'
$ServerADObject = Get-ADComputer -Filter {name -eq $Hostname} -Properties *
if ($ServerADObject.DistinguishedName -ne "CN=$Hostname,$TargetOU") {
	Write-Host "Server AD object in wrong location. Attempting to move to correct location"
	try {
		$ServerADObject | Move-ADObject -TargetPath $TargetOU -ErrorAction Stop
	}
	catch {
		Write-Host "Unable to move the AD object of $Hostname to the correct location." -ForegroundColor Red
		Write-Host $_.Exception.Message -ForegroundColor Red
		Write-Host $_.Exception.ItemName -ForegroundColor Red
	}
}elseif ($ServerADObject.DistinguishedName -eq "CN=$Hostname,$TargetOU") {
	Write-Host "Server AD object already in correct location. No change needed."
}
Write-Host "-------"

<# Local Group Changes (what to add to which local group)
	- foreach group, add specified users
#>
Write-Host 'Attempting to add items to server local groups.'
foreach ($LocalGroup in $XMLConfigFile.PBSC_Config.LocalGroupChanges.localgroup) {
	# $LocalGroup.name
	foreach ($ItemtoAdd in $LocalGroup.AddItem.name) {
		# $ItemtoAdd
		try {
			Add-LocalGroupMember -Group $LocalGroup.name -Member $ItemtoAdd -Confirm:$false -ErrorAction Stop
			write-host "$ItemtoAdd has been added to $($LocalGroup.name)." -ForegroundColor Green
		}
		catch {
			Write-Host "Unable to add $ItemtoAdd to local group $($LocalGroup.name)." -ForegroundColor Red
			Write-Host $_.Exception.Message -ForegroundColor Red
			Write-Host $_.Exception.ItemName -ForegroundColor Red
		}
	}
}
Write-Host "-------"

<# Share Creation (share name and location, share permissions, security permissions)
	- Check if directory exists
		- If not, create it
	- Create Fileshare, permissions while creating
	- add items to NTFS ACL
#>
foreach ($FileShare in $XMLConfigFile.PBSC_Config.NetworkFileShares.FileShare) {
	# $FileShare.name
	# $FileShare.path
	if (!(Test-Path -Path $FileShare.path)) {
		Write-Host "$($FileShare.path) does not exist. Attempting to create directory."
		try {
			New-Item -ItemType Directory -Path $FileShare.path -ErrorAction Stop | Out-Null
			Write-Host "$($FileShare.path) has been created." -ForegroundColor Green
		}
		catch {
			Write-Host "Unable to create the directory (Path: $($FileShare.path))." -ForegroundColor Red
			Write-Host $_.Exception.Message -ForegroundColor Red
			Write-Host $_.Exception.ItemName -ForegroundColor Red			
		}
	} elseif (Test-Path -Path $FileShare.path) {
		Write-Host "$($FileShare.path) already exists."
	}
	Write-Host "Checking for SMBShare."
	try {
		Get-SmbShare -Name $FileShare.name -ErrorAction Stop | Out-Null
		Write-Host "The SMB Share $($FileShare.name) already exists."
	}
	catch {
		Write-Host "SMB share $($FileShare.name) does not exist. Attempting to create share."
		try {
			New-SmbShare -Name $FileShare.name -Path $FileShare.path -ErrorAction Stop | Out-Null
			Write-host "SMB share $($FileShare.name) has been created." -ForegroundColor Green
		}
		catch {
			Write-Host "Unable to create the SMB share $($FileShare.name)." -ForegroundColor Red
			Write-Host $_.Exception.Message -ForegroundColor Red
			Write-Host $_.Exception.ItemName -ForegroundColor Red
		}
	}
	foreach ($SharePermission in $Fileshare.SharePermissions.additem) {
		# $SharePermission.name
		# $SharePermission.permissionlevel
		try {
			Grant-SmbShareAccess -Name $FileShare.name -AccountName $SharePermission.name -AccessRight $SharePermission.permissionlevel -Confirm:$false -ErrorAction Stop | Out-Null
			Write-Host "$($SharePermission.permissionlevel) access has been granted to $($SharePermission.name) on $($FileShare.name)." -ForegroundColor Green
		}
		catch {
			Write-Host "Unable to grant $($SharePermission.permissionlevel) access for $($SharePermission.name) to $($FileShare.name)." -ForegroundColor Red
			Write-Host $_.Exception.Message -ForegroundColor Red
			Write-Host $_.Exception.ItemName -ForegroundColor Red
		}
	}
	foreach ($ACLChange in $FileShare.ACLChanges.additem) {
		# $ACLChange.name
		# $ACLChange.PermissionLevel
		# $FileShare.path
		try {
			$FolderACL = Get-Item -Path $FileShare.path -ErrorAction Stop | get-acl -ErrorAction Stop
			$NewACL = New-Object  system.security.accesscontrol.filesystemaccessrule $ACLChange.name,$ACLChange.PermissionLevel,'ContainerInherit, ObjectInherit','None','Allow'  -ErrorAction Stop
			$FolderACL.SetAccessRule($NewACL)
			Set-Acl $FileShare.path $FolderACL -ErrorAction Stop
			Write-Host "$($ACLChange.PermissionLevel) access has been granted to $($ACLChange.name) for $($FileShare.path). " -ForegroundColor Green
		}
		catch {
			Write-Host "Unable to grant $($ACLChange.PermissionLevel) access to $($ACLChange.name) for $($FileShare.path)." -ForegroundColor Red
			Write-Host $_.Exception.Message -ForegroundColor Red
			Write-Host $_.Exception.ItemName -ForegroundColor Red
		}
	}
}

<# Config Changes
	- Unused portion - planned for future use
#>