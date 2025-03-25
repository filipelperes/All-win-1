function DrawMenu {
	param ($menuItems, $menuPosition, $Multiselect, $selection, $color)
	$l = $menuItems.length
	for ($i = 0; $i -le $l; $i++) {
		if ($null -ne $menuItems[$i]) {
			$item = $menuItems[$i]
			if ($Multiselect) {
				if ($selection -contains $i) {
					$item = '[x] ' + $item
				}
				else {
					$item = '[ ] ' + $item
				}
			}
			if ($i -eq $menuPosition) {
				Write-Host "> $($item)" -ForegroundColor $color
			}
			else {
				Write-Host "  $($item)"
			}
		}
	}
}

function ToggleSelection {
	param ($pos, [array]$selection)
	if ($selection -contains $pos) {
		$result = $selection | Where-Object { $_ -ne $pos }
	}
	else {
		$selection += $pos
		$result = $selection
	}
	$result
}

function Menu {
	param ([array]$menuItems, [switch]$ReturnIndex = $false, [switch]$Multiselect, [string]$color)
	$vkeycode = 0
	$pos = 0
	$selection = @()
	if ($menuItems.Length -gt 0) {
		try {
			$startPos = [System.Console]::CursorTop
			[console]::CursorVisible = $false #prevents cursor flickering
			DrawMenu $menuItems $pos $Multiselect $selection $color
			While ($vkeycode -ne 13 -and $vkeycode -ne 39) {
				# 13 = Enter ou Return | 39 = seta para direita
				$press = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown")
				$vkeycode = $press.virtualkeycode
				if ($vkeycode -eq 38 -or $press.Character -eq 'k') {
					# 38 = seta para cima
					if ($pos -eq 0) { $pos = $menuItems.Length - 1 } else { $pos-- }
				}
				if ($vkeycode -eq 40 -or $press.Character -eq 'j') {
					# 40 = seta para baixo
					if ($pos -eq ($menuItems.Length - 1)) { $pos = 0 } else { $pos++ }
				}
				if ($vkeycode -eq 36 -or $pos -lt 0) { $pos = 0 } # 36 = home
				if ( $vkeycode -eq 35 -or $pos -ge $menuItems.Length ) { $pos = $menuItems.Length - 1 } # 35 = end
				if ($press.Character -eq ' ') { $selection = ToggleSelection $pos $selection }
				if ($vkeycode -eq 27 -or $press.Character -in @('e', 'q')) { exit } # 27 = escape
				if ($vkeycode -eq 37 -or $press.Character -eq 'b') { return "Back" } # 37 = seta para esquerda
				if ($press.Character -eq 'v') { return "View Shortcuts Keys" }
				$startPos = [System.Console]::CursorTop - $menuItems.Length
				[System.Console]::SetCursorPosition(0, $startPos)
				DrawMenu $menuItems $pos $Multiselect $selection $color
			}
		}
		finally {
			[System.Console]::SetCursorPosition(0, $startPos + $menuItems.Length)
			[console]::CursorVisible = $true
		}
	}
	else {
		$pos = $null
	}

	if ($ReturnIndex -eq $false -and $null -ne $pos) {
		if ($Multiselect) {
			return $menuItems[$selection]
		}
		else {
			return $menuItems[$pos]
		}
	}
	else {
		if ($Multiselect) {
			return $selection
		}
		else {
			return $pos
		}
	}
}

function Show-Keys {
	Write-Host @"
$("`n" * 5)
Shortcuts Keys:
   - $( [char] 8593 ) / $( [char] 8595 ) or "k"/"j" to Navigate
   - "Home" to go to the first option
   - "End" to go to the last option
   - "Enter" or $( [char] 8594 ) to Select
   - "b" or $( [char] 8592 ) to go Back
   - "Escape" or "e" or "q" to Exit
   - "v" to view shortcuts keys
"@ -ForegroundColor Gray
}

function Get-MenuOptions {
	param ( $options, [switch]$submenu )

	return @(
		$options
		if ($submenu) { [PSCustomObject]@{ Label = "Back"; Action = { return } } }
		else { [PSCustomObject]@{ Label = "View Shortcuts Keys"; Action = { Show-Keys } } }
		[PSCustomObject]@{ Label = "Exit"; Action = { exit } }
	)
}