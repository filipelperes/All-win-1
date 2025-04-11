. "$PSScriptRoot\utils\recursive.ps1"
. "$PSScriptRoot\utils\json.ps1"

$scoopPackages = (GetJsonObject -fileName "scoop").Packages

function CheckScoop {
   if (Get-Command scoop -ErrorAction SilentlyContinue) { return $true } else { return $false }
}

function Install-Scoop {
   Set-ExecutionPolicy RemoteSigned -Scope Process -Force
   Invoke-Expression "& {$(Invoke-RestMethod -Uri "https://get.scoop.sh")} -RunAsAdmin"
}

function Update-Scoop { scoop update }
function ScoopExport { scoop export --output $global:scoopJSONFileBkp }
function ScoopImport {
   if (-not (Test-Path $global:scoopJSONFileBkp)) {
      Write-Host "$global:space`Backup file not detected. Did it go on vacation? Let’s double-check that path!" -ForegroundColor Yellow
      return
   }

   scoop import $global:scoopJSONFileBkp
}

function GetPackageName {
   param (
      [string]$package
   )

   return (scoop info $package | Select-String -Pattern "Name\s*:\s*(.*)").Matches.Groups[1].Value.Trim()
}

function ScoopUpdate {
   param ( [string]$package = "*" )
   scoop update $package
}

function ScoopInstall {
   param ( $package )
   scoop install $package -Y
}

function ScoopInstallAll {
   if (-not (( Get-IterableObject -obj $scoopPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   ScoopInstall -package (ArrayToString -array $scoopPackages -separator " ")
}

function InteractingWithScoopData {
   if (-not (( Get-IterableObject -obj $scoopPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   $menuOptions = foreach ($item in $scoopPackages) {
      $current = $item
      [PSCustomObject]@{
         Label  = $current
         Action = { ScoopInstall -package $current }
      }
   }

   Show-Menu -options $menuOptions -title (GetBoxedText -text "Select a Package") -submenu
   return
}

$scoopMenu = if (-not (CheckScoop)) {
   [PSCustomObject]@{ Label = "Install Scoop" ; Action = { Install-Scoop } }
}
else {
   [PSCustomObject]@{
      Description = "Scoop"
      Label       = "Scoop"
      Submenu     = @(
         [PSCustomObject]@{ Label = "Backup/Export Installed Packages" ; Action = { ScoopExport } }
         [PSCustomObject]@{ Label = "Install a Package" ; Action = { InteractingWithScoopData } }
         [PSCustomObject]@{ Label = "Install All" ; Action = { ScoopInstallAll } }
         [PSCustomObject]@{ Label = "Restore/Import Packages" ; Action = { ScoopImport } }
         [PSCustomObject]@{ Label = "Update All Scoop Installed Packages" ; Action = { ScoopUpdate } }
         [PSCustomObject]@{ Label = "Update Scoop" ; Action = { Update-Scoop } }
      )
   }
}