Param(
	[parameter(Mandatory=$false)]
	[String]
	$VCenterServer = 'dmi-win-vcenter.donegalgroup.com'
)

Connect-VIServer -Server $VCenterServer

get-vm * | Get-Snapshot | Select-Object VM, Name, Created, Description, SizeGB | Out-GridView -Title "VMs with Snapshots" -PassThru

Disconnect-VIServer -Server dmi-win-vcenter.donegalgroup.com -Confirm:$false