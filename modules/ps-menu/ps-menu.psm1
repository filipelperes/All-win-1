$keysMap = [PSCustomObject]@{
	32 = { # 32 = Space Bar
		param ( [ref]$menuPos, $menuItemsLength, [ref]$selection, $Multiselect )
		if ($Multiselect) {
			if ( $selection.Value -contains $menuPos.Value ) { $selection.Value = $selection.Value | Where-Object { $_ -ne $menuPos.Value } }
			else { $selection.Value += $menuPos.Value }
		}
	}
	35 = { # 35 = End
		param ( [ref]$menuPos, $menuItemsLength )
		$menuPos.Value = $menuItemsLength - 1
	}
	36 = { # 36 = Home
		param ( [ref]$menuPos )
		$menuPos.Value = 0
	}
	38 = { # 38 = Arrow Up (↑)
		param ( [ref]$menuPos, $menuItemsLength )
		if ($menuPos.Value -eq 0) { $menuPos.Value = $menuItemsLength - 1 } else { $menuPos.Value-- }
	}
	40 = { # 40 = Arrow Down (↓)
		param ( [ref]$menuPos, $menuItemsLength )
		if ($menuPos.Value -eq ($menuItemsLength - 1)) { $menuPos.Value = 0 } else { $menuPos.Value++ }
	}
}

$charactersMap = [PSCustomObject]@{
	"K" = {
		param ( [ref]$menuPos, $menuItemsLength )
		& $keysMap.38 $menuPos $menuItemsLength # 38 = Arrow Up (↑)
	}
	"J" = {
		param ( [ref]$menuPos, $menuItemsLength )
		& $keysMap.40 $menuPos $menuItemsLength # 40 = Arrow Down (↓)
	}
	"C" = {
		param ( [ref]$menuPos, $menuItemsLength, [ref]$title, $separator, [ref]$separatorLine, $separatorLength, [ref]$shortcuts  )
		$newTheme = @($box.SingleDash.Light, $box.SingleDash.Heavy, $box.DoubleDash) | Get-Random
		while ($newTheme -eq $Script:theme) { $newTheme = @($box.SingleDash.Light, $box.SingleDash.Heavy, $box.DoubleDash) | Get-Random }
		$Script:theme = $newTheme
		if ($title.Value) { $title.Value.Title = (GetBoxedText -text $(($title.Value.Title -split "`n")[1]) -separatorLength $separatorLength -centered) -join "`n" }
		if ($separator) { $separatorLine.Value = "  $("$($theme.Horizontal)" * ($separatorLength - 2))" }
		if ($shortcuts.Value) { $shortcuts.Value.BoxedShortcuts = (GetBoxedText -text "'C' to Change Box Theme ; $($shortcuts.Value.Shortcuts.Text -join " ; ")" -separatorLength $separatorLength) -join "`n" }
	}
}

$box = [PSCustomObject]@{
	SingleDash = [PSCustomObject]@{
		Light = [PSCustomObject]@{
			Horizontal       = [char]0x2500  # ─
			VerticalAndRight = [char]0x251C	# ├
			VerticalAndLeft  = [char]0x2524  # ┤
			DownAndRight     = [char]0x250C  # ┌
			UpAndRight       = [char]0x2514  # └
			DownAndLeft      = [char]0x2510 # ┐
			UpAndLeft        = [char]0x2518 # ┘
		}
		Heavy = [PSCustomObject]@{
			Horizontal       = [char]0x2501  # ─
			VerticalAndRight = [char]0x2523  # ├
			VerticalAndLeft  = [char]0x252B  # ┤
			DownAndRight     = [char]0x250f  # ┌
			UpAndRight       = [char]0x2517  # └
			DownAndLeft      = [char]0x2513  # ┐
			UpAndLeft        = [char]0x251B  # ┘
		}
	}
	DoubleDash = [PSCustomObject]@{
		Horizontal       = [char]0x2550  # ═
		VerticalAndRight = [char]0x2560  # ╠
		VerticalAndLeft  = [char]0x2563  # ╣
		DownAndRight     = [char]0x2554  # ╔
		UpAndRight       = [char]0x255A  # ╚
		DownAndLeft      = [char]0x2557  # ╗
		UpAndLeft        = [char]0x255D  # ╝
	}
}

$theme = @($box.SingleDash.Light, $box.SingleDash.Heavy, $box.DoubleDash) | Get-Random

function HandleKeyPress {
	param (
		[ref]$pos,
		[ref]$selection,
		[ref]$title,
		[ref]$separatorLine,
		[ref]$shortcuts,
		$separator,
		$separatorLength,
		$vkeycode,
		$character,
		$menuItemsLength,
		[switch]$Multiselect
	)
	if ($keysMap.$vkeycode) { & $keysMap.$vkeycode $pos $menuItemsLength $selection $Multiselect }
	elseif ($character -and $charactersMap.$character) { & $charactersMap.$character $pos $menuItemsLength $title $separator $separatorLine $separatorLength $shortcuts }
}

function Get-MenuArea {
	param (
		$title,
		$menuItemsLength,
		$pageSize,
		$shortcuts,
		[switch]$separator,
		[switch]$pagination
	)

	$menuArea = 0
	if ($title) { $menuArea += $title.Length }
	$menuArea += $menuItemsLength
	if ($shortcuts) { $menuArea += 3 }
	if ($separator) { $menuArea += 2 }

	return $menuArea
}

function CenterText {
	param (
		[string]$text,
		[int]$width
	)
	$padding = [math]::Max(0, [math]::Floor(($width - $text.Length) / 2))
	$line = "$($theme.Horizontal)" * 3
	return "$($theme.VerticalAndRight)$line$(" " * ($padding - 5))$text$(" " * ($padding - $(if ($separatorLength -ge 110) { 0 } else { 1 })))$line$($theme.VerticalAndLeft)"
}

function GetBoxedText {
	param ( [string]$text, [int]$separatorLength = 107, [switch]$centered )
	$line = "$($theme.Horizontal)" * $separatorLength
	if ($centered) { $text = $text.Substring(4, $separatorLength - 6).Trim() }

	return @(
		"$($theme.DownAndRight)$line$($theme.DownAndLeft)"
		(CenterText -text $text -width $separatorLength)
		"$($theme.UpAndRight)$line$($theme.UpAndLeft)"
	)
}

function Get-Title {
	param ( $title, [int]$separatorLength )

	if ($title -and $title -is [string]) {
		$title = GetBoxedText -text ("$($title.ToUpper()) MENU") -separatorLength $separatorLength
	}

	return $(
		if (-not $title) { $null }
		else {
			[PSCustomObject]@{
				Title  = ($title -join "`n")
				Length = $title.Count
			}
		}
	)
}

function Get-Shortcuts {
	param ( $shortcuts )

	return $(
		if (-not $shortcuts) { $null }
		else {
			[PSCustomObject]@{
				Shortcuts      = $shortcuts
				Keys           = $shortcuts.Keys
				BoxedShortcuts = (GetBoxedText -text "'C' to Change Box Theme ; $($shortcuts.Text -join " ; ")" -separatorLength $separatorLength) -join "`n"
			}
		}
	)
}

function Menu {
	param (
		$title,
		[array]$menuItems,
		$shortcuts,
		$color,
		[switch]$ReturnIndex = $false,
		[switch]$Multiselect,
		[switch]$separator,
		[switch]$pagination,
		$separatorLength = 107
	)

	$pos = 0
	$vkeycode = 0
	$selection = @()
	$shortcut = $null

	$title = Get-Title -title $title -separatorLength $separatorLength
	$menuItemsLength = $menuItems.Count
	$shortcuts = Get-Shortcuts -shortcuts $shortcuts
	$menuArea = Get-MenuArea -title $title -menuItemsLength $menuItemsLength -shortcuts $shortcuts -separator:$separator
	$separatorLine = " $("$($theme.Horizontal)" * ($separatorLength))"

	if ($menuItemsLength -gt 0) {
		[System.Console]::CursorVisible = $false #prevents cursor flickering
		$windowHeight = $host.UI.RawUI.WindowSize.Height - 1
		DrawMenu -title $title -menuItems $menuItems -shortcuts $shortcuts -color $color -menuPosition $pos -selection $selection -windowHeight $windowHeight -menuArea $menuArea -menuItemsLength $menuItemsLength -Multiselect:$Multiselect -separator:$separator -separatorLength $separatorLength -separatorLine $separatorLine

		While ($vkeycode -notin @(13, 39) -and -not $shortcut) {
			# 13 = Enter/Return | 39 = Arrow Right (→)
			$press = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
			$vkeycode = $press.virtualkeycode
			$character = $press.Character

			HandleKeyPress -vkeycode $vkeycode -character $character -pos ([ref]$pos) -menuItemsLength $menuItemsLength -selection ([ref]$selection) -Multiselect:$Multiselect -title ([ref]$title) -separatorLine ([ref]$separatorLine) -separator $separator -separatorLength $separatorLength -shortcuts ([ref]$shortcuts)

			if ($shortcuts -and ($shortcuts.Keys -contains $character -or $shortcuts.Keys -contains $vkeycode)) {
				$shortcut = ($shortcuts.Shortcuts.Where({ $_.Keys -contains $(if ($shortcuts.Keys -contains $character) { $character } else { $vkeycode }) })).For
			}

			$windowHeight = $host.UI.RawUI.WindowSize.Height - 1
			[System.Console]::CursorTop = if ($menuArea -gt $windowHeight) { 0 }
			else { [math]::Max(0, [System.Console]::CursorTop - $menuArea) }
			DrawMenu -title $title -menuItems $menuItems -shortcuts $shortcuts -color $color -menuPosition $pos -selection $selection -windowHeight $windowHeight -menuArea $menuArea -menuItemsLength $menuItemsLength -Multiselect:$Multiselect -separator:$separator -separatorLength $separatorLength -separatorLine $separatorLine
		}

	}
	else { $pos = $null }
	[System.Console]::CursorVisible = $true

	return Get-SelectedValue -menuItems $menuItems -selection $selection -pos $pos -Multiselect:$Multiselect -ReturnIndex:$ReturnIndex -shortcut $shortcut
}

function Get-SelectedValue {
	param (
		$menuItems,
		$selection,
		$pos,
		$shortcut,
		[switch]$Multiselect,
		[switch]$ReturnIndex
	)

	$value = if ($Multiselect) { $selection } else { $pos }
	if (-not $ReturnIndex -and $null -ne $pos) { $value = $menuItems[$value] }

	return $(
		if (-not $shortcut) { $value }
		else { @($shortcut, @($value)) }
	)
}

function DrawMenu {
	param (
		$title,
		$menuItems,
		$shortcuts,
		$color,
		$menuPosition,
		$selection,
		$windowHeight,
		$menuArea,
		$menuItemsLength,
		$Multiselect,
		$separator,
		$separatorLength,
		$separatorLine
	)

	$windowWidth = $host.UI.RawUI.WindowSize.Width
	$startIndex = 0
	$items = $menuItems

	if ($menuArea -gt $windowHeight) {
		$menuItemsLength = $windowHeight - ( $menuArea - $menuItemsLength )
		if ($menuPosition -ge $menuItemsLength) { $startIndex = $menuPosition - $menuItemsLength + 1 }
		$items = $menuItems | Select-Object -Skip $startIndex -First $menuItemsLength
	}

	if ($title) { Write-Host $title.Title }
	if ($separator) { Write-Host $separatorLine -ForegroundColor Gray }

	foreach ($item in $items) {
		if ($null -eq $item) { continue }
		if ($Multiselect) { $item = "[$(if ($selection -contains $startIndex) { "X" } else { " " })] $item" }
		$item = $item.PadRight($windowWidth - $item.Length, ' ')
		if ($startIndex -eq $menuPosition) { Write-Host "> $item" -ForegroundColor $color } else { Write-Host "  $item" }
		$startIndex++
	}

	if ($separator) { Write-Host $separatorLine -ForegroundColor Gray }
	if ($shortcuts) { Write-Host $shortcuts.BoxedShortcuts }
}