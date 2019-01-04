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

<# Local Group Changes
	- foreach group
		- Check if user/group is already a member
			-if not, add to local group
#>
foreach ($LocalGroup in $XMLConfigFile.PBSC_Config.LocalGroupChanges.localgroup) {
	# $LocalGroup.name
	foreach ($ItemtoAdd in $LocalGroup.AddItem.name) {
		# $ItemtoAdd
		if (!(Get-LocalGroupMember -Name $LocalGroup.name -Member $ItemtoAdd -ErrorAction SilentlyContinue )) {
			try {
				Add-LocalGroupMember -Group $LocalGroup.name -Member $ItemtoAdd -Confirm:$false -ErrorAction Stop
				write-host "$ItemtoAdd has been added to $($LocalGroup.name)." -ForegroundColor Green
			}
			catch {
				Write-Host "Unable to add $ItemtoAdd to local group $($LocalGroup.name)." -ForegroundColor Red
				Write-Host $_.Exception.Message -ForegroundColor Red
				Write-Host $_.Exception.ItemName -ForegroundColor Red
			}	
		}elseif (Get-LocalGroupMember -Name $LocalGroup.name -Member $ItemtoAdd ) {
			Write-Host "$ItemtoAdd is already a member of $($LocalGroup.name)."
		}
	}
}
Write-Host "-------"

<# Share Creation (share name and location, share permissions, security permissions)
	- Check if directory exists
		- If not, create it
	- Check for SMB share exists
		- If not, create it
	- Check if each Share Permissions is already granted
		- If not, grant it
	- Check if NTFS permissions have been added
		- if not, add items to NTFS ACL
#>
foreach ($FileShare in $XMLConfigFile.PBSC_Config.NetworkFileShares.FileShare) {
	# $FileShare.name
	# $FileShare.path
	#Check if Directory exists. If not, create it.
	if (!(Test-Path -Path $FileShare.path)) {
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

	#Check if SMB Share exists. If not, create it.
	try {
		Get-SmbShare -Name $FileShare.name -ErrorAction Stop | Out-Null
		Write-Host "The SMB Share $($FileShare.name) already exists."
	}
	catch {
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

	#Check if Share Permissions exist. If not, add permissions. If incorrect, readd permission.
	foreach ($SharePermission in $Fileshare.SharePermissions.additem) {
		# $SharePermission.name
		# $SharePermission.permissionlevel
		$SMBShareAccess = Get-SmbShareAccess -Name $FileShare.name | Where-Object {$_.AccountName -eq $SharePermission.name }
		if ($SMBShareAccess.AccessRight -ne $SharePermission.permissionlevel) {
			try {
				Grant-SmbShareAccess -Name $FileShare.name -AccountName $SharePermission.name -AccessRight $SharePermission.permissionlevel -Confirm:$false -ErrorAction Stop | Out-Null
				Write-Host "$($SharePermission.permissionlevel) access has been granted to $($SharePermission.name) on $($FileShare.name)." -ForegroundColor Green
			}
			catch {
				Write-Host "Unable to grant $($SharePermission.permissionlevel) access for $($SharePermission.name) to $($FileShare.name)." -ForegroundColor Red
				Write-Host $_.Exception.Message -ForegroundColor Red
				Write-Host $_.Exception.ItemName -ForegroundColor Red
			}
		} elseif ($SMBShareAccess.AccessRight -eq $SharePermission.permissionlevel) {
			Write-Host "$($SharePermission.name) already has $($SharePermission.permissionlevel) access to $($FileShare.name)."
		}
	}

	#Check if NTFS ACL exists. If not, add it. If incorrect, readd permission.
	foreach ($ACLChange in $FileShare.ACLChanges.additem) {
		# $ACLChange.name
		# $ACLChange.PermissionLevel
		# $FileShare.path
		try {
			$FolderACL = Get-Item -Path $FileShare.path -ErrorAction Stop | get-acl -ErrorAction Stop
			$FolderACLCheck = $FolderACL.access | Where-Object {$_.IdentityReference -eq $ACLChange.name}
			if (!($FolderACLCheck.FileSystemRights -like "$($ACLChange.PermissionLevel)*")) {
				$NewACL = New-Object  system.security.accesscontrol.filesystemaccessrule $ACLChange.name,$ACLChange.PermissionLevel,'ContainerInherit, ObjectInherit','None','Allow'  -ErrorAction Stop
				$FolderACL.SetAccessRule($NewACL)
				Set-Acl $FileShare.path $FolderACL -ErrorAction Stop
				Write-Host "$($ACLChange.PermissionLevel) access has been granted to $($ACLChange.name) for $($FileShare.path). " -ForegroundColor Green
			} elseif ($FolderACLCheck.FileSystemRights -like "$($ACLChange.PermissionLevel)*") {
				Write-Host "$($ACLChange.name) already has $($ACLChange.PermissionLevel) access to $($FileShare.path)."
			}
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