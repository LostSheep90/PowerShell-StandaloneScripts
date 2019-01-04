$TargetOU = $XMLConfigFile.PBSC_Config.ServerADOU.name
$Hostname = $env:computername
# $TargetOU = "CN=Computers,DC=donegalgroup,DC=com"
# $Hostname = 'JF-DIG-LAPTOP1'
$ServerADObject = Get-ADComputer -Filter {name -eq $Hostname} -Properties *

<# Move AD Computer object to correct AD Group
	- Check if the AD object is not in the correct location.
		- If not in the correct location, move the server object
#>
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