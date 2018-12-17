<#
todo:
add export to excel option. toggle option with true/false command line switch

add option to output total size of folders. toggle option with true/false command line switch

get debugging and verbose working. 
#>

$ExportPath = [Environment]::GetFolderPath("Desktop") + "\OutlookFolderInfo.csv"
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
   $Size = $Size/1MB
   Return $Size
}

function Get-OutlookFolderSubFoldersandInfo {
   param (
      $Subfolder
   )
   
   # $Size = Get-OulookFolderSize ($Subfolder)
   # Write-Debug $Subfolder.Name " - " $Subfolder.Items.Count " - " $Size

   $Global:ListofOutlookFolderInformation += $Subfolder | Select-Object (
      @{ Label="Folder"; Expression={$($Subfolder.name)} },
      @{ Label="SubfolderCount"; Expression={$($Subfolder.Folders.Count)} },
      @{ Label="ItemCount"; Expression={$($Subfolder.Items.Count)} },
      # @{ Label="SizeMB"; Expression={"{0:n1}" -f $size} },
      @{ Label="FullPath"; Expression={$($Subfolder.FullFolderPath)} }
   )

   # Write-Host "-----------------------------------------------------------"
   # $Global:ListofOutlookFolderInformation
   # Write-Host "-----------------------------------------------------------"

   If($Subfolder.folders.count -gt 0) {
      foreach ($Folder in $Subfolder.Folders) {
         Get-OutlookFolderSubFoldersandInfo($Folder)
      }
   }
   
}

foreach ($Subfolder in $OutlookRootFolder.Folders) {
   Get-OutlookFolderSubFoldersandInfo($Subfolder)
}

# $Global:ListofOutlookFolderInformation | Export-Excel -Now -Show -AutoSize
$Global:ListofOutlookFolderInformation | Export-Csv -Path $ExportPath -NoTypeInformation
Invoke-Expression $ExportPath