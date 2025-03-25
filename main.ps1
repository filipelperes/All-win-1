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
. "$PSScriptRoot\modules\tweaks.ps1"
. "$PSScriptRoot\modules\winget.ps1"
. "$PSScriptRoot\modules\utils\arrays.ps1"

Import-Module "$PSScriptRoot\modules\ps-menu\ps-menu.psd1"

if ((checkWingetSupport) -and -not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

$menu = @(
    $4devsMenu
    $chocolateyMenu
    if ($global:OSVersion -eq 10) { $pwshThemesMenu }
    $environmentVariablesMenu
    [PSCustomObject]@{
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
    $scoopMenu
    $tweaksMenu
    if (checkWingetSupport) { $wingetMenu }
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
        [switch]$submenu,
        $titleName,
        [switch]$sorted
        #[PSCustomObject[]]$prevMenu
    )

    $options = Get-MenuOptions -options $(if ($sorted) { $options } else { $options | Sort-Object -Property Label }) -submenu:$submenu

    $title = if ($null -eq $titleName) { $null }
    elseif ($titleName -is [object[]] -or $titleName -is [array]) { $titleName }
    else {
        @(
            $("=" * 88) #Length = 60
                (CenterText -text "$($titleName.ToUpper()) MENU" -width 88)
            $("=" * 88)
        )
    }

    while ($true) {
        # cls
        Write-Output "$global:space$(if ($null -ne $title) { "$(ArrayToString -array $title -separator "`n")`n" })"

        $selection = Menu -menuItems $options.Label -color "Green"
        $selectedOption = $options | Where-Object { $_.Label -eq $selection }


        if ($selectedOption.Submenu) {
            Show-Menu -options $selectedOption.Submenu -titleName $selectedOption.Description -submenu # -prevMenu $options
        }

        if ($selectedOption.Action) {
            & $selectedOption.Action
            if (($selectedOption.Label -eq "Back" -and $submenu) -or $selectedOption.Label -eq "< Back / Less") { return }
            if (($selectedOption.Label -match "^Using (NPM|Yarn|PNPM)$")) { break }
        } # elseif ($selection -eq "Back") { Show-Menu -options $prevMenu }
    }
}

Write-Host "`n`n$(CenterText -text "Press 'v' to view shortcuts keys" -width 88)" -ForegroundColor Gray
Show-Menu -options $menu -titleName "Main"

<# Set-Location $HOME\Desktop #>

# Pausa para visualizar erros
# Read-Host -Prompt "Pressione Enter para continuar"