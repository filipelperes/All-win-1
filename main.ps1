if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Oops! I need admin powers to proceed. Could you flex your admin muscles and try again?"
    exit
}

. "$PSScriptRoot\globals.ps1"
. "$PSScriptRoot\modules\4devs.ps1"
. "$PSScriptRoot\modules\chocolatey.ps1"
. "$PSScriptRoot\modules\environmentVariables.ps1"
. "$PSScriptRoot\modules\pwshThemes.ps1"
. "$PSScriptRoot\modules\scoop.ps1"
. "$PSScriptRoot\modules\themes.ps1"
. "$PSScriptRoot\modules\tweaks.ps1"
. "$PSScriptRoot\modules\winget.ps1"
. "$PSScriptRoot\modules\utils\arrays.ps1"

Import-Module "$PSScriptRoot\modules\ps-menu\ps-menu.psd1"

if ((checkWingetSupport) -and -not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

$settingsMenu = [PSCustomObject]@{
    Description = "Settings"
    Label       = "Settings"
    Submenu     = @(
        [PSCustomObject]@{ Label = "Open Additional Mouse Settings"; Action = { Start-Process "control.exe" -ArgumentList "main.cpl" -Verb RunAs } },
        [PSCustomObject]@{ Label = "Open Additional Power Settings"; Action = { Start-Process "control.exe" -ArgumentList "powercfg.cpl" -Verb RunAs } },
        [PSCustomObject]@{ Label = "Open Background Settings"; Action = { Start-Process "ms-settings:personalization-background" } },
        [PSCustomObject]@{ Label = "Open Colors Settings"; Action = { Start-Process "ms-settings:colors" } },
        [PSCustomObject]@{ Label = "Open Display Settings"; Action = { Start-Process "ms-settings:display" } },
        [PSCustomObject]@{ Label = "Open Environment Variables Settings"; Action = { Start-Process "rundll32.exe" -ArgumentList "sysdm.cpl,EditEnvironmentVariables" -Verb RunAs } },
        [PSCustomObject]@{ Label = "Open Lockscreen Settings"; Action = { Start-Process "ms-settings:lockscreen" } },
        [PSCustomObject]@{ Label = "Open Mouse Settings"; Action = { Start-Process "ms-settings:mousetouchpad" } },
        [PSCustomObject]@{ Label = "Open Multitasking Settings"; Action = { Start-Process "ms-settings:multitasking" } },
        [PSCustomObject]@{ Label = "Open Optional Features Settings (Advanced Users)"; Action = { Start-Process "ms-settings:optionalfeatures" } },
        [PSCustomObject]@{ Label = "Open Performance Settings"; Action = { SystemPropertiesPerformance -Verb RunAs } },
        [PSCustomObject]@{ Label = "Open Power Settings"; Action = { Start-Process "ms-settings:powersleep" } },
        [PSCustomObject]@{ Label = "Open Start Menu Settings"; Action = { Start-Process "ms-settings:personalization-start" } },
        [PSCustomObject]@{ Label = "Open System Properties Settings"; Action = { SystemPropertiesAdvanced -Verb RunAs } },
        [PSCustomObject]@{ Label = "Open Taskbar Settings"; Action = { Start-Process "ms-settings:taskbar" } }
    )
}

$mainMenu = @(
    $4devsMenu
    $chocolateyMenu
    $environmentVariablesMenu
    $pwshThemesMenu
    $scoopMenu
    $settingsMenu
    $themesMenu
    $tweaksMenu
    $wingetMenu
)

function CenterText {
    param (
        [string]$text,
        [int]$width
    )
    $padding = [math]::Max(0, [math]::Floor(($width - $text.Length) / 2))
    $("-" * 5) + (" " * ($padding - 5)) + $text + (" " * ($padding - 4)) + $("-" * 5)
}

function Show-Menu {
    param (
        [PSCustomObject[]]$options,
        $title,
        [switch]$submenu,
        [switch]$sorted,
        [switch]$pagination,
        [switch]$descending,
        $page = 0
        #[PSCustomObject[]]$prevMenu
    )

    if (-not $sorted) { $options = $options | Sort-Object -Property Label -Descending:$descending }
    $menuItems = if ($pagination) { @() } else { $options }

    if ($pagination) {
        $pageSize = 27
        $skip = $page * $pageSize
        $hasMore = ($skip + $pageSize) -lt $options.Count

        if ($page -gt 0) {
            $menuItems += [PSCustomObject]@{ Label = "<< Back | Less" ; Action = { return } }
        }

        $menuItems = @( $menuItems ) + @( $options | Select-Object -Skip $skip -First $pageSize )

        if ($hasMore) {
            $menuItems += [PSCustomObject]@{
                Label  = "Next | More >>"
                Action = [scriptblock]::Create("Show-Menu -options `$options -title `$title -submenu -sorted -pagination -page $($page + 1)")
            }
        }
    }


    if ($title -and $title -is [string]) {
        $title = @(
            $("=" * 88)
            (CenterText -text "$($title.ToUpper()) MENU" -width 88)
            $("=" * 88)
        )
    }

    $menuItems = Get-MenuItems -items $menuItems -submenu:$submenu

    while ($true) {
        # cls
        Write-Output "$global:space$(if ($null -ne $title) { "$(ArrayToString -array $title -separator "`n")`n" })"

        $selection = Menu -menuItems $menuItems.Label -color "Green"
        $selectedOption = $menuItems | Where-Object { $_.Label -eq $selection }


        if ($selectedOption.Submenu) {
            Show-Menu -options $selectedOption.Submenu -title $selectedOption.Description -submenu -sorted:$sorted -pagination:$pagination -descending:$descending -page $page # -prevMenu $menuItems
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

Write-Host "`n`n$(CenterText -text "Press 'v' to view shortcuts keys" -width 88)" -ForegroundColor Gray
Show-Menu -options $mainMenu -title "Main"

# Set-Location 'D:\Programming\Projetos\Windows Sync' ; Set-ExecutionPolicy RemoteSigned -Scope Process -Force; .\main.ps1
<# Set-Location $HOME\Desktop #>