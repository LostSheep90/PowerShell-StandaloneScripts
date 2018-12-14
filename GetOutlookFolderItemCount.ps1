$OutlookObject = new-object -comobject outlook.application
$OutlookObjectNamespace = $OutlookObject.GetNamespace("MAPI")
$OutlookRootFolder = $OutlookObjectNamespace.GetDefaultFolder(6).Parent
$Global:ListofOutlookFolderInformation = @()

function Get-OulookFolderSize {
   param (
      $Folder
   )
   $FolderItemCount = $Folder.items.count
   foreach ($Item in $Folder.Items) {
      $Itemcount ++
      $ProgressUpdate ++
      $Size = $Size + $Item.Size
      if ($ProgressUpdate -ge 50) {
         $ProgressUpdate = 0
         Write-Progress -Activity ("Toting size of " + $foldername + " folder.") -Status ("Totaling size of " + $Itemcount + " of " + $folderItemCount + " emails.") -PercentComplete ($itemcount/$folderItemCount*100)
      }
   }
   $Size = $Size/1024
   Return $Size
}

function Get-OutlookFolderSubFolders {
   param (
      $Subfolder
   )
   
   $Size = Get-OulookFolderSize ($Subfolder)
   # Write-Host $Subfolder.Name " - " $Subfolder.Items.Count " - " $Size

   $Global:ListofOutlookFolderInformation += $Subfolder | Select-Object (
      @{ Label="Folder"; Expression={$($Subfolder.name)} },
      @{ Label="ItemCount"; Expression={$($Subfolder.Items.Count)} },
      @{ Label="SizeKB"; Expression={"{0:n1}" -f $size} },
      @{ Label="FullPath"; Expression={$($Subfolder.FullFolderPath)} }
   )

   # Write-Host "-----------------------------------------------------------"
   # $Global:ListofOutlookFolderInformation
   # Write-Host "-----------------------------------------------------------"

   If($Subfolder.folders.count -gt 0) {
      foreach ($Folder in $Subfolder.Folders) {
         Get-OutlookFolderSubFolders($Folder)
      }
   }
   
}

foreach ($Subfolder in $OutlookRootFolder.Folders) {
   # Get-OulookFolderInfo ($Subfolder)
   If($Subfolder.folders.count -gt 0) {
      Get-OutlookFolderSubFolders($Subfolder)
   } else {
      Write-Host $Subfolder.Name
   }
}

$Global:ListofOutlookFolderInformation | Export-Excel -Now -Show -AutoSize