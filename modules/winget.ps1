﻿. "$PSScriptRoot\utils\recursive.ps1"
. "$PSScriptRoot\utils\json.ps1"
. "$PSScriptRoot\utils\arrays.ps1"

$wingetPackages = (GetJsonObject -fileName "winget").Packages

function checkWingetSupport {
   <#
   if ($null -eq $sync.ComputerInfo) { $ComputerInfo = Get-ComputerInfo -ErrorAction Stop }
   else { $ComputerInfo = $sync.ComputerInfo }
   return $(if (($ComputerInfo.WindowsVersion) -lt "1809") { $false } else { $true })
   #>
   return $(if (($global:OSVersion -eq 10 -and $global:OSBuild -ge 16299) -or $global:OSVersion -gt 10) { $true } else { $false })

}

function Install-WingetOnWSB {
   $progressPreference = 'silentlyContinue'
   Write-Host "Installing WinGet PowerShell module from PSGallery..."
   Install-PackageProvider -Name NuGet -Force | Out-Null
   Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
   Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
   Repair-WinGetPackageManager
   Write-Host "Done."
}

function Update-Winget {
   #winget upgrade winget
   #winget upgrade Microsoft.AppInstaller
   winget install -e Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements
}

function AcceptMSStoreTerms {
   $region = (Get-Culture).TwoLetterISOLanguageName
   $sourceAgreements = winget source list --name "msstore" -ErrorAction SilentlyContinue
   if (-not $sourceAgreements) {
      winget source add --name "msstore" --accept-source-agreements
      winget settings set region --value $region
   }
}

function WingetExport { winget export -o $global:wingetJSONFileBkp }
function WingetImport {
   if (-not (Test-Path $global:wingetJSONFileBkp)) {
      Write-Host "$global:space`Backup file not detected. Did it go on vacation? Let’s double-check that path!" -ForegroundColor Yellow
      return
   }

   winget import -i $global:wingetJSONFileBkp
}

function WingetInstall {
   param (
      [string]$package,
      [switch]$extract,
      $source = $null
   )

   if ($extract) { $package = ExtractWingetId -package $package -source $source }

   Write-Output "$("`n" * 3)Installing $((GetPackageName -package $package -line) -replace "Found ", '')"
   winget install --id $package --accept-package-agreements
}

function WingetUninstall {
   param (
      [string]$package,
      [switch]$extract
   )

   if ($extract) { $package = ExtractWingetId -package $package }

   Write-Output "$("`n" * 3)Uninstalling $((GetPackageName -package $package -line) -replace "Found ", '')"
   winget uninstall --id $package --all
}

function WingetUpdate {
   param (
      $package = "all",
      [switch]$extract
   )

   if ($extract) { $package = ExtractWingetId -package $package }

   Write-Output "$("`n" * 3)Updating $((GetPackageName -package $package -line) -replace "Found ", '')"
   & ([scriptblock]::Create("winget upgrade $(if ($package -eq "all") { "--all --uninstall-previous" } else { "--id '$package'" }) --accept-package-agreements"))
}

function GetPackageName {
   param (
      [string]$package,
      [switch]$line
   )

   $name = winget show $package | Select-String -Pattern "Found\s*(.+?)\s*\["
   return $(
      if ($null -eq $name) { $null }
      elseif ($line) { $name.Line }
      else { $name.Matches.Groups[1].Value }
   )
}

function ExtractWingetId {
   param ( $package, $source = $null )

   $fromMSStore = $package -match "msstore\s*$" -or $source -eq "msstore"
   $fromWinget = $package -match "winget\s*$" -or $source -eq "winget"
   $pattern = if ($fromMSStore) { '\b((9|X)[A-Z0-9]+)\b' } elseif ($fromWinget) { '\b([\w-]+\.[\w-]+(?:\.[\w-]+)*)\b' }
   $package = [regex]::Matches($package, $pattern)

   return $(
      if ($package.Value -is [string]) { $package.Value }
      else {
         $i = 0

         while ($true) {
            $name = GetPackageName -package $package.Value[$i]
            if (-not $name) { $i++ } else { break }
         }

         $package.Value[$i]
      }
   )
}

function InteractingWithWingetData {
   param (
      [switch]$install,
      [switch]$add,
      [ValidateSet("Module", "Category", "Package")][string]$by,
      $module,
      $category,
      $package,
      $source = $null
   )

   if (-not (( Get-IterableObject -obj $wingetPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   $isModule = -not $module
   $isCategory = $module -and -not $category
   $isPackage = $install -and $by -eq "Package" -and $module -and $category

   $options = if ($isModule) { $wingetPackages.PSObject.Properties.Name }
   elseif ($isCategory) { $wingetPackages.$module.PSObject.Properties.Name | Where-Object { $_ -ne "ignore" } }
   else { $wingetPackages.$module.$category }

   if ($isPackage -and -not ($options.Count -gt 0)) {
      Write-Warning "Nothing here, folks!"
      return
   }

   $menuOptions = foreach ($item in $options) {
      # $current = $item
      # $label  = $item
      # $label  = if ($isPackage) { (GetPackageName -package $item) } else { $item }
      $label = if ($isPackage -and $item -match '^((9|X)[A-Z0-9]+)$') { ((GetPackageName -package $item -line) -replace "Found ", '') } else { $item }
      $action = if ($install) {
         switch ($by) {
            "Module" { "ActionWingetInstall -by 'Module' -obj `$wingetPackages.'$item'" }
            "Category" {
               if ($isModule) { "InteractingWithWingetData -install -by 'Category' -module '$item'" }
               else { "ActionWingetInstall -by 'Category' -obj `$wingetPackages.'$module'.'$item'" }
            }
            "Package" {
               if ($isModule -or $isCategory) { "InteractingWithWingetData -install -by 'Package' -module $( if($isModule) { "'$item'" } else { "'$module' -category '$item'" } )" }
               else { "WingetInstall -package '$item'" }
            }
         }
      }
      else {
         if ($isModule) { "InteractingWithWingetData -add -package '$package' -module '$item' -source `$source" }
         else { "ActionAddToData -package '$package' -module '$module' -category '$item' -source `$source" }
      }

      [PSCustomObject]@{ Label = $label ; Action = [scriptblock]::Create($action) }
   }

   if ($add) {
      $menuOptions = @(
         ($menuOptions | Sort-Object -Property Label)
         [PSCustomObject]@{
            Label  = "New"
            Action = [scriptblock]::Create("ActionAddToData -package `$package $( if ($isCategory) { "-module `$module" } ) -source `$source")
         }
      )
   }

   Show-Menu -options $menuOptions -title $null -submenu -sorted:$add
   return
}

function InteractingWithWingetInstalledPackages {
   param (
      [switch]$update,
      [switch]$uninstall
   )

   $packages = & ([scriptblock]::Create("winget list $( if ($update) { "--upgrade-available" } else { "| Where-Object { `$_ -notmatch '(MSIX|ARP)\\' }" } )"))

   $i = index -array $packages -value "^Name\s+Id\s+Version(?:\s+Available)?\s+Source$"
   $title = @("  $($packages[$i])", "  $("_" * $($packages[($i + 1)].Length))")
   $options = $packages | Select-Object -Skip ($i + 2)
   $aux = 0

   $menuItems = foreach ($item in $options) {
      if ($update -and $aux -eq ($options.Count - 1)) { break }

      [PSCustomObject]@{
         Label  = $item
         Action = [scriptblock]::Create("$(if ($update) { "WingetUpdate" } else { "WingetUninstall" }) -package '$item' -extract")
      }

      $aux++
   }

   Show-Menu -options $menuItems -title $title -submenu -pagination
   return
}

function ActionWingetInstall {
   param (
      [ValidateSet("Module", "Category", "All")][string]$by,
      $obj = $wingetPackages
   )

   if (-not (( Get-IterableObject -obj $obj ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   Write-Host $("`n" * 5)

   engaging -obj $obj -processItem {
      param ( $item, $k, $v )
      #$module = $k
      switch ($by) {
         "Category" { WingetInstall -package $v }
         "Module" {
            if ($k -eq "Ignore") { continue }
            engaging -obj $v -processItem {
               param ( $item, $k, $v )
               WingetInstall -package $v
            }
         }
         "All" {
            engaging -obj $v -processItem {
               param ( $item, $k, $v )
               if ($k -eq "Ignore") { continue }
               #$category = $k
               engaging -obj $v -processItem {
                  param ( $item, $k, $v )
                  WingetInstall -package $v
               }
            }
         }
      }
   }
}

function SearchWingetPackages {
   $pattern = '^$'
   $source = $null

   Write-Host @"
$("`n" * 5)
Options:
   -d, -desc,-descending               : Sort in Descending Order (Ascending by default)
   -s, -source ('winget' or 'msstore') : Filter by a specific source

Example: Telegram -d -s winget

"@ -ForegroundColor Green

   while (-not $package -or $package -match $pattern) {
      $package = (Read-Host "What's the magic word? (Or, you know, the package name you want to search for?) or 'exit'/'back'/'cancel'").Trim()
      if ($package -in @("exit", "back", "cancel")) { return }
   }

   $descPattern = "(?i)\s+-(desc|descending|d)"
   $sourcePattern = "(?i)\s+-(source|s)\s+(msstore|winget)"

   $descending = $package -match $descPattern
   $hasSource = $package -match $sourcePattern

   if ($descending) { $package = $package -replace $descPattern, '' }
   if ($hasSource) {
      $source = if ($package -match "msstore") { "msstore" } else { "winget" }
      $package = $package -replace $sourcePattern, ''
   }

   $action = [scriptblock]::Create("winget search -q '$package' $( if ($hasSource) { "--source '$source'" } )")

   $search = & $action
   if ($search[-1] -eq "No package found matching input criteria.") {
      Write-Host "`nAre you sure that package is a real thing? We've checked everywhere. Nothing." -ForegroundColor Yellow
      return
   }

   $titlePattern = "^Name\s+Id\s+Version(?:\s+Match)?(?:\s+Source)?$"
   if (-not ($search | Select-String -Pattern $titlePattern -Quiet)) { $search = & $action }

   $i = index -array $search -value $titlePattern
   $title = @("  $($search[$i])", "  $("_" * $($search[($i + 1)].Length))")
   $packages = $search | Select-Object -Skip ($i + 2)

   $options = foreach ($item in $packages) {
      [PSCustomObject]@{
         Label  = $item
         Action = [scriptblock]::Create("SearchWingetPackagesActions -package '$item' -source `$source")
      }
   }

   Show-Menu -options $options -title $title -submenu -pagination -descending:$descending
   return
}

function SearchWingetPackagesActions {
   param ( $package, $source = $null )

   Show-Menu -options @(
      [PSCustomObject]@{ Label = "Add To Data" ; Action = { InteractingWithWingetData -add -package $package -source $source } }
      [PSCustomObject]@{ Label = "Install" ; Action = { WingetInstall -package $package -source $source -extract } }
   ) -title $null -submenu

   return
}

function ActionAddToData {
   param (
      $package,
      $module,
      $category,
      $source = $null
   )

   $pattern = '^$'
   $data = GetJsonObject -fileName "winget"

   while (-not $module -or $module -match $pattern) {
      $module = (Read-Host "$("`n" * 3)New Module Name or 'exit'/'back'/'cancel'").Trim().ToLower()
      if ($module -in @("exit", "back", "cancel")) { return }
      if ($module -in $data.Packages.PSObject.Properties.Name) {
         Write-Host "Module already exist!" -ForegroundColor Yellow
         $module = $null
         continue
      }
   }

   if (-not $data.Packages.$module) { $data.Packages | Add-Member -MemberType NoteProperty -Name $module -Value ([PSCustomObject]::new()) }

   while (-not $category -or $category -match $pattern) {
      $category = (Read-Host "$("`n" * 2)New Category Name or 'exit'/'back'/'cancel'").Trim().ToLower()
      if ($category -in @("exit", "back", "cancel")) { return }
      if ($category -in $data.Packages.$module.PSObject.Properties.Name) {
         Write-Host "$("`n" * 2)Category already exist!" -ForegroundColor Yellow
         $category = $null
         continue
      }
   }

   if (-not $data.Packages.$module.$category) { $data.Packages.$module | Add-Member -MemberType NoteProperty -Name $category -Value @() }

   $package = ExtractWingetId -package $package -source $source

   if ($package -notin $data.Packages.$module.$category) {
      $data.Packages.$module.$category += $package

      if (
         ($data.Packages.$module.$category -is [array] -or $data.Packages.$module.$category -is [object[]]) -and
         ($data.Packages.$module.$category.Count -gt 1)
      ) { $data.Packages.$module.$category = ( $data.Packages.$module.$category | Sort-Object ) }

      # engaging -obj $data.Packages -processItem {
      #    param ( $item, $k, $v )
      #    $module = $k
      #    engaging -obj $v -processItem {
      #       param ( $item, $k, $v )
      #       if (($v -is [array] -or $v -is [object[]]) -and $v.Count -gt 1) { $data.Packages.$module.$k = $v | Sort-Object }
      #    }
      # }

      ExportJson -data $data -filePath "$PSScriptRoot\..\data\winget.json"
      $script:wingetPackages = (GetJsonObject -fileName "winget").Packages
   }
   else { Write-Host "$("`n" * 3)Package already exist!" -ForegroundColor Yellow }

   return
}

function CheckBrokenPackages {
   if (-not (( Get-IterableObject -obj $wingetPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   Write-Host $("`n" * 5)

   engaging -obj $wingetPackages -processItem {
      param ( $item, $k, $v )
      $module = $k
      engaging -obj $v -processItem {
         param ( $item, $k, $v )
         $category = $k
         if ($k -eq "Ignore") { continue }
         engaging -obj $v -processItem {
            param ( $item, $k, $v )
            if ($null -eq (GetPackageName -package $v)) {
               Write-Host @"
* ==> FOUND BROKEN PACKAGE <== *
   Module   : $module
   Category : $category
   Package  : $v

"@ -ForegroundColor Red
            }
         }
      }
   }
}

function ViewAllWingetData {
   Write-Output $("`n" * 3)
   PrintOnScreen $wingetPackages -wget
}

$wingetMenu = if (checkWingetSupport) {
   [PSCustomObject]@{
      Description = "Winget"
      Label       = "Winget"
      Submenu     = @(
         [PSCustomObject]@{ Label = "Accept Microsoft Store Terms" ; Action = { AcceptMSStoreTerms } }
         [PSCustomObject]@{ Label = "Backup/Export Installed Packages" ; Action = { WingetExport } }
         [PSCustomObject]@{ Label = "Check Broken Packages From JSON Data" ; Action = { CheckBrokenPackages } }
         [PSCustomObject]@{ Label = "Install a Category" ; Action = { InteractingWithWingetData -install -by "Category" } }
         [PSCustomObject]@{ Label = "Install a Module" ; Action = { InteractingWithWingetData -install -by "Module" } }
         [PSCustomObject]@{ Label = "Install a Package" ; Action = { InteractingWithWingetData -install -by "Package" } }
         [PSCustomObject]@{ Label = "Install All" ; Action = { ActionWingetInstall -by "All" } }
         [PSCustomObject]@{ Label = "Install Winget on Windows Sandbox (Advanced Users)" ; Action = { Install-WingetOnWSB } }
         [PSCustomObject]@{ Label = "Restore/Import Packages" ; Action = { WingetImport } }
         [PSCustomObject]@{ Label = "Search" ; Action = { SearchWingetPackages } }
         [PSCustomObject]@{ Label = "Uninstall a Package" ; Action = { InteractingWithWingetInstalledPackages -uninstall } }
         [PSCustomObject]@{ Label = "Update a Package" ; Action = { InteractingWithWingetInstalledPackages -update } }
         [PSCustomObject]@{ Label = "Update All Installed Packages" ; Action = { WingetUpdate } }
         [PSCustomObject]@{ Label = "Update Source Repos" ; Action = { winget source update } }
         [PSCustomObject]@{ Label = "Update Winget" ; Action = { Update-Winget } }
         [PSCustomObject]@{ Label = "View All Data" ; Action = { ViewAllWingetData } }
         if ($global:OSBuild -ge 26100) { [PSCustomObject]@{ Label = "Repair Winget Using Repair-WinGetPackageManager" ; Action = { Repair-WinGetPackageManager -Force -Latest -Verbose } } }
      )
   }
}