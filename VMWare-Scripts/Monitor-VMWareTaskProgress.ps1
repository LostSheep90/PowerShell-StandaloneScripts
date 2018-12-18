try {
    Write-Host "Attempting to connect to vCenter."
    Connect-VIServer -Server dmi-win-vcenter.donegalgroup.com -ErrorAction Stop -ErrorVariable vCenterConnError
}
catch {
    Write-Host "Unable to connect to vCenter." -ForegroundColor Red
    Write-Host " "
    Write-Host $vCenterConnError
    Pause
    Break
}

if ((Get-Task -Status Running).Count -gt 0) {
    try {
        $Task = get-task -Status Running -ErrorAction Stop -ErrorVariable GetTaskError | Out-GridView -PassThru -Title "Select only one task."
    }
    catch {
        Write-Host "Unable to get list of vCenter Tasks." -ForegroundColor Red
        Write-Host " "
        Write-Host $GetTaskError
        Pause
        Disconnect-VIServer -Confirm:$false
        Break
    }
} elseif ((Get-Task -Status Running).Count -eq 0) {
    Write-host "0 Running Tasks in vCenter." -ForegroundColor Green
    Disconnect-VIServer -Confirm:$false
    Break
}

$EstTimeToComplete = {
    $Elapse = $(get-date) - $($Task.StartTime)
    $SecondsRemaining = ($Elapse.totalseconds / $Progress) * ($Complete - $Progress)
    $TS = New-TimeSpan -Seconds $SecondsRemaining
    $estttc = $(get-date) + $ts
    return "Task is running... Estimated completion time: $estttc"
}

$Complete = 100
$StatusCheckDelay = 5

do {
    $Progress = Get-Task -Id $Task.Id | Select-Object -ExpandProperty PercentComplete
    Write-Progress -id 0 -Activity "Monitoring $($Task.Name)" -PercentComplete (($Progress/$Complete)*100) -Status "$Progress% Complete" -CurrentOperation (& $EstTimeToComplete)
    $Count = $StatusCheckDelay
    do {
        Write-Progress -id 1 -ParentId 0 -Activity " " -PercentComplete ((($StatusCheckDelay-$Count)/$StatusCheckDelay)*100) -Status "Seconds until the next update: $Count"
        $Count --
        Start-Sleep -Seconds 1
    } until ($Count -eq 0)
} until ($Progress -ge $Complete)

Write-Host "Monitored task has completed."

Disconnect-VIServer -Confirm:$false

Pause