if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Oops! I need admin powers to proceed. Could you flex your admin muscles and try again?"
    exit
}

$PreventLoad = @( "tests.ps1", "bkp.ps1", "clear.ps1", "generateProjectStructure.ps1", "main.ps1" )
foreach ($item in (Get-ChildItem $PSScriptRoot -Recurse)) {
    if ($item.Name -like "*.ps1" -and $PreventLoad -notcontains $item.Name) { . $item.FullName }
}

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

# Write-Host "`n`n$(CenterText -text "Press 'v' to view shortcuts keys" -width 88)" -ForegroundColor Gray
Show-Menu -options @(
    $4devsMenu
    $chocolateyMenu
    $environmentVariablesMenu
    $pwshThemesMenu
    $scoopMenu
    $settingsMenu
    $themesMenu
    $tweaksMenu
    $wingetMenu
) -title "Main"

# Set-Location 'D:\Programming\Projetos\Windows Sync' ; Set-ExecutionPolicy RemoteSigned -Scope Process -Force; .\main.ps1
<# Set-Location $HOME\Desktop #>