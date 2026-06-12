if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Warning "This script requires PowerShell 3.0 or later. Current version: $($PSVersionTable.PSVersion)"
    exit
}

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires administrator privileges. Please run as Administrator."
    exit
}

# Load core utilities (dependency order)
. "$PSScriptRoot\modules\utils\arrays.ps1"
. "$PSScriptRoot\modules\utils\recursive.ps1"
. "$PSScriptRoot\modules\utils\json.ps1"
. "$PSScriptRoot\modules\utils\utils.ps1"

# Load globals (depends on json.ps1)
. "$PSScriptRoot\modules\globals.ps1"

# Load configuration
. "$PSScriptRoot\config.ps1"

# Load menu system
Import-Module "$PSScriptRoot\modules\ps-menu\ps-menu.psd1"
. "$PSScriptRoot\modules\menu.ps1"

# Load feature modules
. "$PSScriptRoot\modules\winget.ps1"
. "$PSScriptRoot\modules\chocolatey.ps1"
. "$PSScriptRoot\modules\scoop.ps1"
. "$PSScriptRoot\modules\environmentVariables.ps1"
. "$PSScriptRoot\modules\4devs.ps1"
. "$PSScriptRoot\modules\pwshThemes.ps1"
. "$PSScriptRoot\modules\themes.ps1"
. "$PSScriptRoot\modules\tweaks.ps1"
. "$PSScriptRoot\modules\settings.ps1"

if ((checkWingetSupport) -and -not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

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
