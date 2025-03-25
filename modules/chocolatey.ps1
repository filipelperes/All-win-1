. "$PSScriptRoot\utils\recursive.ps1"
. "$PSScriptRoot\utils\json.ps1"

$chocoPackages = (GetJsonObject -fileName "chocolatey").Packages

function CheckChocolatey {
   if (Get-Command choco -ErrorAction SilentlyContinue) { return $true } else { return $false }
}

function Install-Chocolatey {
   Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function ChocoExport { choco export -o=$global:chocoConfigFileBkp --include-version-numbers }
function ChocoImport {
   if (-not (Test-Path $global:chocoConfigFileBkp)) {
      Write-Host "$global:space`Backup file not detected. Did it go on vacation? Let’s double-check that path!" -ForegroundColor Yellow
      return
   }

   choco install $global:chocoConfigFileBkp -y
}

function GetPackageName {
   param (
      [string]$package
   )

   return (choco info $package | Select-String -Pattern "Title\s*:\s*(.*)").Matches.Groups[1].Value.Trim()
}

function ChocoInstall {
   param ( [string]$package )

   choco install $package -y
}

function ChocoUpgrade {
   param (
      [string]$package = "all"
   )

   choco upgrade $package -y
}

function ChocoInstallAll {
   if (-not (( Get-IterableObject -obj $chocoPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   ChocoInstall -package (ArrayToString -array $chocoPackages -separator " ")
}

function InteractingWithChocoData {
   if (-not (( Get-IterableObject -obj $chocoPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   #$isPackage = $by -eq "Package" -and $module -and $category

   $menuOptions = foreach ($item in $chocoPackages) {
      $current = $item
      [PSCustomObject]@{
         #Label  = if ($isPackage) { (GetPackageName -package $current) } else { $current }
         Label  = $current
         Action = { ChocoInstall -package $current }
      }
   }

   Show-Menu -options $menuOptions -titleName $null -submenu
   return
}

$chocolateyMenu = if (-not (CheckChocolatey)) {
   [PSCustomObject]@{ Label = "Install Chocolatey" ; Action = { Install-Chocolatey } }
}
else {
   [PSCustomObject]@{
      Description = "Chocolatey"
      Label       = "Chocolatey"
      Submenu     = @(
         [PSCustomObject]@{ Label = "Backup/Export Installed Packages" ; Action = { ChocoExport } }
         [PSCustomObject]@{ Label = "Install Chocolatey GUI" ; Action = { ChocoInstall -package "chocolateygui" ; ChocoUpgrade -package "chocolateygui" } }
         [PSCustomObject]@{ Label = "Install All" ; Action = { ChocoInstallAll } }
         [PSCustomObject]@{ Label = "Install Packages" ; Action = { InteractingWithChocoData } }
         [PSCustomObject]@{ Label = "Restore/Import Packages" ; Action = { ChocoImport } }
         [PSCustomObject]@{ Label = "Synchronize System Packages With Chocolatey" ; Action = { choco sync -y | Out-Null } }
         [PSCustomObject]@{ Label = "Update All Chocolatey Installed Packages" ; Action = { ChocoUpgrade } }
         [PSCustomObject]@{ Label = "Update Chocolatey" ; Action = { ChocoUpgrade -package "chocolatey" } }
      )
   }
}
