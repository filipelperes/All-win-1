. "$PSScriptRoot\utils\recursive.ps1"
. "$PSScriptRoot\utils\json.ps1"
. "$PSScriptRoot\utils\arrays.ps1"

$wingetPackages = (GetJsonObject -fileName "winget").Packages

function checkWingetSupport {
   <#
   if ($null -eq $sync.ComputerInfo) { $ComputerInfo = Get-ComputerInfo -ErrorAction Stop }
   else { $ComputerInfo = $sync.ComputerInfo }
   if (($ComputerInfo.WindowsVersion) -lt "1809") { return $false } else { return $true }
   #>
   if (($global:OSVersion -eq 10 -and $global:OSBuild -ge 16299) -or $global:OSVersion -gt 10) { return $true } else { return $false }
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

function AcceptWingetTerms {
   $region = (Get-Culture).TwoLetterISOLanguageName
   $sourceAgreements = winget source list
   if ($sourceAgreements -notmatch "msstore") {
      winget source add --name msstore --arg "--accept-source-agreements"
      winget settings set region --value $region
   }
}

function WingetUpdateAll { winget upgrade --all --uninstall-previous }
function WingetExport { winget export -o $global:wingetJSONFileBkp }
function WingetImport {
   if (-not (Test-Path $global:wingetJSONFileBkp)) {
      Write-Host "$global:space`Backup file not detected. Did it go on vacation? Let’s double-check that path!" -ForegroundColor Yellow
      return
   }

   winget import -i $global:wingetJSONFileBkp
}

function GetPackageName {
   param (
      [string]$package,
      [switch]$line
   )

   $name = winget show $package | Select-String -Pattern "Found\s*(.+?)\s*\["
   if ($null -eq $name) { return $null }
   else {
      if ($line) { return $name.Line }
      else { return $name.Matches.Groups[1].Value }
   }
}

function WingetInstall {
   param (
      [string]$package
   )

   Write-Output "`nInstalling $((GetPackageName -package $package -line) -replace "Found ", '')"
   winget install --id $package --accept-package-agreements
}

function InteractingWithWingetData {
   param (
      [switch]$install,
      [switch]$add,
      [ValidateSet("Module", "Category", "Package")][string]$by,
      $module,
      $category,
      $package
   )

   if (-not (( Get-IterableObject -obj $wingetPackages ).Count -gt 0 )) {
      Write-Host "$global:space`Data lost and found? More like just 'lost' here. Nothing to see. Let's see if we can 'find' something by checking that path! (Check path!)" -ForegroundColor Yellow
      return
   }

   $isModule = -not $module
   $isCategory = $module -and -not $category
   $isPackage = $by -eq "Package" -and $module -and $category

   $options = if ($isModule) { $wingetPackages.PSObject.Properties.Name }
   elseif ($isCategory) { $wingetPackages.$module.PSObject.Properties.Name | Where-Object { $_ -ne "ignore" } }
   else { $wingetPackages.$module.$category }

   $menuOptions = foreach ($item in $options) {
      # $current = $item
      # $label  = $item
      # $label  = if ($isPackage) { (GetPackageName -package $item) } else { $item }
      $label = if ($isPackage -and $item -match '\b((9|X)[A-Z0-9]+)\b') { (GetPackageName -package $item) } else { $item }
      $action = if ($install) {
         switch ($by) {
            "Module" { "InstallActionWinget -by 'Module' -obj `$wingetPackages.'$item'" }
            "Category" {
               if ($isModule) { "InteractingWithWingetData -install -by 'Category' -module '$item'" }
               else { "InstallActionWinget -by 'Category' -obj `$wingetPackages.'$module'.'$item'" }
            }
            "Package" {
               if ($isModule) { "InteractingWithWingetData -install -by 'Package' -module '$item'" }
               elseif ($isCategory) { "InteractingWithWingetData -install -by 'Package' -module '$module' -category '$item'" }
               else { "WingetInstall -package '$item'" }
            }
         }
      }
      else {
         if ($isModule) { "InteractingWithWingetData -add -package '$package' -module '$item'" }
         else { "AddToData -package '$package' -module '$module' -category '$item'" }
      }

      [PSCustomObject]@{ Label = $label ; Action = [scriptblock]::Create($action) }
   }

   if ($add) {
      $menuOptions = @(
         ($menuOptions | Sort-Object -Property Label)
         [PSCustomObject]@{
            Label  = "New"
            Action = if ($isModule) { { AddToData -package $package } } elseif ($isCategory) { { AddToData -package $package -module $module } }
         }
      )
   }

   Show-Menu -options $menuOptions -titleName $null -submenu -sorted:$add
   return
}

function InstallActionWinget {
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
   $package = $null

   Write-Host $global:space

   while ($null -eq $package -or $package -match $pattern) {
      $package = Read-Host "What's the magic word? (Or, you know, the package name you want to search for?) or 'exit'/'back'/'cancel'"
      if ($package.Trim().ToLower() -in @("exit", "back", "cancel")) { return }
   }

   $search = winget search -q $package
   if ($search[-1] -eq "No package found matching input criteria.") {
      Write-Host "`nAre you sure that package is a real thing? We've checked everywhere. Nothing." -ForegroundColor Yellow
      return
   }

   if (-not ($search | Select-String -Pattern "^Name\s+Id\s+Version(?:\s+Match)?\s+Source$" -Quiet)) { $search = winget search -q $package }
   SearchWingetPagination -search $search
}

function SearchWingetPagination {
   param (
      $page = 0,
      $search
   )

   $i = index -array $search -value "^Name\s+Id\s+Version(?:\s+Match)?\s+Source$"
   $titleName = @("  $($search[$i])", "  $("_" * $($search[($i + 1)].Length))")
   $packages = $search | Select-Object -Skip ($i + 2) | Sort-Object

   $pageSize = 27
   $skip = $page * $pageSize
   $hasMore = ($skip + $pageSize) -lt $packages.Count
   $pageOptions = $packages | Select-Object -Skip $skip -First $pageSize

   $options = @()

   if ($page -gt 0) {
      $options += [PSCustomObject]@{
         Label  = "< Back / Less"
         Action = { return }
      }
   }

   $options += foreach ($item in $pageOptions) {
      [PSCustomObject]@{
         Label  = $item
         Action = [scriptblock]::Create("SearchActions -package '$item'")
      }
   }

   if ($hasMore) {
      $options += [PSCustomObject]@{
         Label  = "More / Next >"
         Action = [scriptblock]::Create("SearchWingetPagination -page $($page + 1) -search `$search")
      }
   }

   Show-Menu -options $options -titleName $titleName -submenu -sorted
}

function SearchActions {
   param ( $package )

   #$package = StringToArray -string $package -separator "\s{2,}"
   # $package = [regex]::Matches($package, '\b([\w-]+\.[\w-]+(?:\.[\w-]+)*)\b')
   $sourceMSStore = $package -match "msstore$"
   $pattern = if ($sourceMSStore) { '\b((9|X)[A-Z0-9]+)\b' } else { '\b([\w-]+\.[\w-]+(?:\.[\w-]+)*)\b' }
   $package = [regex]::Matches($package, $pattern)
   $package = if ($sourceMSStore) { $package.Value } else { $package.Value[0] }

   $options = @(
      [PSCustomObject]@{
         Label  = "Install"
         Action = { WingetInstall -package $package }
      }
      [PSCustomObject]@{
         Label  = "Add To Data"
         Action = { InteractingWithWingetData -add -package $package }
      }
   )

   Show-Menu -options $options -titleName $null -submenu:$submenu
   return
}

function AddToData {
   param (
      $package,
      $module,
      $category
   )

   $pattern = '^$'
   $data = GetJsonObject -fileName "winget"

   while (-not $module -or $module -match $pattern) {
      $module = Read-Host "New Module Name or 'exit'/'back'/'cancel'"
      if ($module.Trim().ToLower() -in @("exit", "back", "cancel")) { return }
      if ($module -in $data.Packages.PSObject.Properties.Name) {
         Write-Host "Module already exist!" -ForegroundColor Yellow
         $module = $null
         continue
      }
   }

   if (-not $data.Packages.$module) { $data.Packages | Add-Member -MemberType NoteProperty -Name $module -Value ([PSCustomObject]::new()) }

   while (-not $category -or $category -match $pattern) {
      $category = Read-Host "New Category Name or 'exit'/'back'/'cancel'"
      if ($category.Trim().ToLower() -in @("exit", "back", "cancel")) { return }
      if ($category -in $data.Packages.$module.PSObject.Properties.Name) {
         Write-Host "Category already exist!" -ForegroundColor Yellow
         $category = $null
         continue
      }

   }

   if (-not $data.Packages.$module.$category) { $data.Packages.$module | Add-Member -MemberType NoteProperty -Name $category -Value @() }
   if ($package -notin $data.Packages.$module.$category) { $data.Packages.$module.$category += $package }

   ExportJson -data $data -filePath "$PSScriptRoot\..\data\winget.json"
   $script:wingetPackages = (GetJsonObject -fileName "winget").Packages
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
`n
* BROKEN *
   Module: $module
   Category: $category
   Package: $v
"@ -ForegroundColor Yellow
            }
         }
      }
   }
}

# winget list | Where-Object {$_ -notmatch "MSIX|ARP|Microsoft."}

$wingetMenu = [PSCustomObject]@{
   Description = "Winget"
   Label       = "Winget"
   Submenu     = @(
      [PSCustomObject]@{ Label = "Accept Winget Terms" ; Action = { AcceptWingetTerms } }
      [PSCustomObject]@{ Label = "Backup/Export Installed Packages" ; Action = { WingetExport } }
      [PSCustomObject]@{ Label = "Check Broken Packages From JSON Data" ; Action = { CheckBrokenPackages } }
      [PSCustomObject]@{ Label = "Install Winget on Windows Sandbox (Advanced Users)" ; Action = { Install-WingetOnWSB } }
      [PSCustomObject]@{ Label = "Install All" ; Action = { InstallActionWinget -by "All" } }
      [PSCustomObject]@{ Label = "Install Module" ; Action = { InteractingWithWingetData -install -by "Module" } }
      [PSCustomObject]@{ Label = "Install Category" ; Action = { InteractingWithWingetData -install -by "Category" } }
      [PSCustomObject]@{ Label = "Install Package" ; Action = { InteractingWithWingetData -install -by "Package" } }
      [PSCustomObject]@{ Label = "Restore/Import Packages" ; Action = { WingetImport } }
      [PSCustomObject]@{ Label = "Search" ; Action = { SearchWingetPackages } }
      [PSCustomObject]@{ Label = "Update All Installed Packages" ; Action = { WingetUpdateAll } }
      [PSCustomObject]@{ Label = "Update Winget" ; Action = { Update-Winget } }
      if ($global:OSBuild -ge 26100) { [PSCustomObject]@{ Label = "Repair Winget Using Repair-WinGetPackageManager" ; Action = { Repair-WinGetPackageManager -Force -Latest -Verbose } } }
   )
}