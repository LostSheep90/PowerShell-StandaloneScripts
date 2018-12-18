Connect-VIServer -Server dmi-win-vcenter.donegalgroup.com

get-vm * | Get-Snapshot | Select-Object VM, Name, Created, Description, SizeGB | Out-GridView -Title "VMs with Snapshots" -PassThru

Disconnect-VIServer -Server dmi-win-vcenter.donegalgroup.com -Confirm:$false