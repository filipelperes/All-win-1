function Show-ShortcutKeys {
   Write-Host @"
$("`n" * 5)
Shortcuts Keys:
   • $( [char] 8593 )/$( [char] 8595 ) or "K"/"J" to Navigate
   • "Home" to go to the first option
   • "End" to go to the last option
   • "Enter" or $( [char] 8594 ) to Select
   • "B" or $( [char] 8592 ) to go Back
   • "Escape" or "E" or "Q" to Exit / Quit
   • "V" to See All Shortcuts Keys
"@ -ForegroundColor Gray
}

function Get-ShortcutKeys {
   param ([switch]$submenu)

   return @(
      if ($submenu) {
         [PSCustomObject]@{
            Text = "'B' or $( [char] 8592 ) to Go Back"
            keys = @(37, "B") # 37 = Arrow Left (←)
            For  = "Back"
         }
      }
      else {
         [PSCustomObject]@{
            Text = "'V' to See All Shortcuts Keys"
            keys = @("V")
            For  = "See All Shortcuts Keys"
         }
      }
      [PSCustomObject]@{
         Text = "'Escape'/'Q'/'E'/'X' to Exit / Quit"
         keys = @(27, "E", "Q", "X") # 27 = Escape
         For  = "Exit / Quit"
      }
   )
}

function Get-MenuItems {
   param ( $items, [switch]$submenu )

   return @(
      $items
      if ($submenu) { [PSCustomObject]@{ Label = "Back" ; Action = { return } } }
      [PSCustomObject]@{ Label = "Exit / Quit"; Action = { exit } }
   )
}

function Show-Menu {
   param (
      [PSCustomObject[]]$options,
      $title,
      [switch]$submenu,
      [switch]$sorted,
      [switch]$pagination,
      [switch]$descending,
      $page = 0,
      $pageSize = 27,
      $separatorLength = 107
      #[PSCustomObject[]]$prevMenu
   )

   if (-not $sorted) { $options = $options | Sort-Object -Property Label -Descending:$descending }
   $menuItems = $options

   if ($pagination) {
      $skip = $page * $pageSize
      $hasMore = ($skip + $pageSize) -lt $options.Count
      $menuItems = @(
         if ($page -gt 0) { [PSCustomObject]@{ Label = "<< Back | Less" ; Action = { return } } }
         ($options | Select-Object -Skip $skip -First $pageSize)
         if ($hasMore) {
            [PSCustomObject]@{
               Label  = "Next | More >>"
               Action = [scriptblock]::Create("Show-Menu -options `$options -title `$title -submenu -sorted -pagination -page $($page + 1) -pageSize `$pageSize -separatorLength `$separatorLength")
            }
         }
      )
   }

   $menuItems = Get-MenuItems -items $menuItems -submenu:$submenu
   $shortcuts = Get-ShortcutKeys -submenu:$submenu

   while ($true) {
      # cls
      Write-Host $global:space
      $selection = Menu -title $title -menuItems $menuItems.Label -shortcuts $shortcuts -color "Cyan" -separator -separatorLength $separatorLength

      if ($selection -is [array] -or $selection -is [object[]]) { $selection = $selection[0] }
      if ($selection -eq "See All Shortcuts Keys") {
         Show-ShortcutKeys
         continue
      }

      $selectedOption = $menuItems | Where-Object { $_.Label -eq $selection }

      if ($selectedOption.Submenu) {
         Show-Menu -options $selectedOption.Submenu -title $selectedOption.Description -submenu -sorted:$sorted -pagination:$pagination -descending:$descending -page $page -pageSize $pageSize -separatorLength $separatorLength # -prevMenu $menuItems
      }

      if ($selectedOption.Action) {
         & $selectedOption.Action
         if (
               ($selectedOption.Label -eq "Back" -and $submenu) -or
               ($selectedOption.Label -eq "<< Back / Less")
         ) { return }
         if (
               ($selectedOption.Label -match "^(Using (NPM|Yarn|PNPM))$")
         ) { break }
      } # elseif ($selection -eq "Back") { Show-Menu -options $prevMenu }
   }
}
