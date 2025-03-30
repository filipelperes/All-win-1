. "$PSScriptRoot\utils\arrays.ps1"

function ToggleTheme {
    $themeRegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    $currentSystemTheme = (Get-ItemProperty -Path $themeRegistryPath).SystemUsesLightTheme -bxor 1
    Set-ItemProperty -Path $themeRegistryPath -Name "SystemUsesLightTheme" -Value $currentSystemTheme
    Set-ItemProperty -Path $themeRegistryPath -Name "AppsUseLightTheme" -Value $currentSystemTheme
}

function GetUTCDateTime {
    try {
        $ip = (Invoke-WebRequest -Uri "https://ifconfig.me/ip").Content.Trim()
        $response = Invoke-RestMethod -Uri "http://worldtimeapi.org/api/ip/$ip"
        return [datetime]$response.utc_datetime
    }
    catch {
        Write-Host "$global:space`Error: Failed to get UTC time!`n$_" -ForegroundColor Red
        return $null
    }
}

function CheckDiff {
    param (
        [datetime]$systemTime = (Get-Date),
        [datetime]$referenceTime,
        [int]$thresholdInSeconds = 90
    )

    $difference = [math]::Abs(($systemTime - $referenceTime).TotalSeconds)
    return $difference -gt $thresholdInSeconds
}

function Set-TimeAuto {
    $tzautoupdate = "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate"
    $location = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"

    Set-ItemProperty -Path $tzautoupdate -Name "Start" -Value 3
    Set-ItemProperty -Path $location -Name "Value" "Allow"
    w32tm /resync
    Start-Sleep -Seconds 3
}

function Restart-WindowsTimeService {
    Restart-Service -Name w32time -Force
    Start-Sleep -Seconds 3
}

function Edit-TimeServer {
    w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:YES /update
    w32tm /resync
    Start-Sleep -Seconds 3
}

function FixSystemTime {
    $utcTime = GetUTCDateTime

    if (!$utcTime) {
        Write-Host "$global:space`No internet? No problem... except it's absolutely a problem. Let’s fix that!" -ForegroundColor Yellow
        return
    }

    $steps = @(
        { Set-TimeAuto },
        { Restart-WindowsTimeService },
        { Edit-TimeServer }
    )

    foreach ($step in $steps) { if (CheckDiff -referenceTime (GetUTCDateTime)) { & $step } }
}

function ToggleSecondsToClock {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    if ($null -eq (Get-ItemProperty -Path $path).ShowSecondsInSystemClock) {
        Set-ItemProperty -Path $path -Name "ShowSecondsInSystemClock" -Value 1 -Type DWord
    }
    else {
        $value = (Get-ItemProperty -Path $path).ShowSecondsInSystemClock -bxor 1
        Set-ItemProperty -Path $path -Name "ShowSecondsInSystemClock" -Value $value
    }

    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

function RenamePC {
    $pattern = '^[a-zA-Z0-9]{3,}$'
    $newName = $null

    Write-Host $global:space

    while ($null -eq $newName -or $newName -notmatch $pattern) {
        $newName = (Read-Host "Time for a makeover! Or 'exit'/'back'/'cancel' to keep it ugly.").Trim().ToLower()
        if ($newName -in @("exit", "back", "cancel")) { return }
        if ($newName -notmatch $pattern) {
            Write-Warning "Make sure the name is at least 3 characters long and does not contain special characters."
        }
    }

    try {
        Rename-Computer -NewName $newName -Force -PassThru

        while (-not $restart -or $restart -notmatch $global:yesNoPattern) {
            $restart = (Read-Host "Do you want to restart now? (yes/no)").Trim().ToLower()
            switch -Regex ($restart) {
                $global:noPattern { break }
                $global:yesPattern { Restart-Computer -Force }
            }
        }
    }
    catch {
        Write-Warning "Failed to rename the computer:`n$_"
    }
}

function Open-StartupManager {
    Add-Type -AssemblyName System.Windows.Forms
    taskmgr -Verb RunAs
    Start-Sleep -Seconds 1
    foreach ($key in @("^{TAB}", "^{TAB}", "^{TAB}")) { [System.Windows.Forms.SendKeys]::SendWait($key) }
}

function Block-PS2KeyboardDriverUpdate {
    param (
        [string]$hardwareID,
        [switch]$remove
    )

    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"

    New-Item -Path $regPath -Force | Out-Null


    $deniedDevices = StringToArray -string ((Get-ItemProperty -Path $regPath -Name "DenyDeviceIDs" -ErrorAction SilentlyContinue).DenyDeviceIDs) -separator "`n" | Where-Object { $_ }

    if ($remove) {
        $deniedDevices = $deniedDevices | Where-Object { $_ -ne $hardwareID }
    }
    else {
        if (-not ($deniedDevices -contains $hardwareID)) {
            $deniedDevices += $hardwareID
        }
    }

    if ($deniedDevices) {
        Set-ItemProperty -Path $regPath -Name "DenyDeviceIDs" -Value ( ArrayToString -array $deniedDevices -separator "`n" )
    }
    else {
        Remove-ItemProperty -Path $regPath -Name "DenyDeviceIDs" -ErrorAction SilentlyContinue

    }
}

function ToggleEmbeddedKeyboard {
    $keyboard = Get-PnpDevice | Where-Object { $_.Class -like "Keyboard" -and $_.FriendlyName -match "PS/2" }

    if (!$keyboard) {
        Write-Host "$global:space`Embedded keyboard not found."
        return
    }

    if ($keyboard.Status -eq "OK") {
        Disable-PnpDevice -InstanceId $keyboard.InstanceId -Confirm:$false
        Block-PS2KeyboardDriverUpdate -hardwareID $keyboard.InstanceId
    }
    else {
        Enable-PnpDevice -InstanceId $keyboard.InstanceId -Confirm:$false
        Block-PS2KeyboardDriverUpdate -hardwareID $keyboard.InstanceId -remove
    }
}

function ExplorerTweaks {
    param (
        [switch]$UpdateHiddenItems,
        [switch]$UpdateFileExtensions,
        [switch]$UpdateItemCheckBoxes
    )

    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $values = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue

    switch ($true) {
        $UpdateHiddenItems {
            $newValue = $values.Hidden -bxor 1
            Set-ItemProperty -Path $regPath -Name "Hidden" -Value $newValue
            Set-ItemProperty -Path $regPath -Name "ShowSuperHidden" -Value $newValue
        }

        $UpdateFileExtensions {
            Set-ItemProperty -Path $regPath -Name "HideFileExt" -Value ($values.HideFileExt -bxor 1)
        }

        $UpdateItemCheckBoxes {
            Set-ItemProperty -Path $regPath -Name "AutoCheckSelect" -Value ($values.AutoCheckSelect -bxor 1)
        }
    }
}

function Enable-GodMode {
    $Path = "$HOME\GodMode"
    New-Item -Path $Path -ItemType Directory -ErrorAction Stop | Out-Null
    Rename-Item -Path $Path -NewName "GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -ErrorAction Stop
    Write-Host "$global:space`God Mode enabled at $Path." -ForegroundColor Green
}

function Enable-MaxPerformancePowerPlan {
    powercfg -duplicatescheme "ded574b5-45a0-4f42-8737-46345c09c238" | Out-Null
    powercfg -duplicatescheme "e9a42b02-d5df-448d-aa00-03f14749eb61" | Out-Null
}

function Get-AsciiCode {
    param ( [ConsoleKey]$key )
    return [int][char][ConsoleKey]::$key
}

function FixWindowsStore {
    wsreset.exe
    Add-AppxPackage -register "C:\Program Files\WindowsApps\Microsoft.WindowsStore*\AppxManifest.xml" -DisableDevelopmentMode
}

$CARWI = [PSCustomObject]@{
    Label   = "Check and Repair Windows Image"
    Submenu = @(
        [PSCustomObject]@{ Label = "DISM /Online /Cleanup-Image /CheckHealth" ; Action = { DISM /Online /Cleanup-Image /CheckHealth } }
        [PSCustomObject]@{ Label = "DISM /Online /Cleanup-Image /ScanHealth" ; Action = { DISM /Online /Cleanup-Image /ScanHealth } }
        [PSCustomObject]@{ Label = "DISM /Online /Cleanup-Image /RestoreHealth" ; Action = { DISM /Online /Cleanup-Image /RestoreHealth } }
        [PSCustomObject]@{ Label = "All" ; Action = { DISM /Online /Cleanup-Image /CheckHealth ; DISM /Online /Cleanup-Image /ScanHealth ; DISM /Online /Cleanup-Image /RestoreHealth } }
    )
}

$tweaksMenu = [PSCustomObject]@{
    Description = "Tweaks"
    Label       = "Tweaks"
    Submenu     = @(
        [PSCustomObject]@{ Label = "Check and Repair System Files" ; Action = { sfc /scannow } }
        $CARWI
        [PSCustomObject]@{ Label = "Enable GodMode (Advanced Users)" ; Action = { Enable-GodMode } }
        [PSCustomObject]@{ Label = "Enable Maximum Performance Power Plan (Advanced Users)" ; Action = { Enable-MaxPerformancePowerPlan } }
        [PSCustomObject]@{ Label = "Enable/Disable Embedded Keyboards (For Notebooks)" ; Action = { ToggleEmbeddedKeyboard } }
        [PSCustomObject]@{ Label = "Fix Date And Hour" ; Action = { FixSystemTime } }
        [PSCustomObject]@{ Label = "Fix Windows Store" ; Action = { FixWindowsStore } }
        [PSCustomObject]@{ Label = "Open MSConfig" ; Action = { msconfig -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open Regedit (Advanced Users)" ; Action = { regedit } }
        [PSCustomObject]@{ Label = "Open Startup Manager" ; Action = { Open-StartupManager } }
        [PSCustomObject]@{ Label = "Open Task Manager" ; Action = { taskmgr -Verb RunAs } }
        [PSCustomObject]@{ Label = "Open User Account Control (UAC) (Advanced Users)" ; Action = { UserAccountControlSettings } }
        if ($global:OSVersion -eq 11) { [PSCustomObject]@{ Label = "Reinstall Powershell" ; Action = { Get-WindowsFeature -Name PowerShell | Install-WindowsFeature } } }
        [PSCustomObject]@{ Label = "Rename Computer" ; Action = { RenamePC } }
        [PSCustomObject]@{ Label = "Toggle Explorer File Extensions" ; Action = { ExplorerTweaks -UpdateFileExtensions } }
        [PSCustomObject]@{ Label = "Toggle Explorer Hidden Items" ; Action = { ExplorerTweaks -UpdateHiddenItems } }
        [PSCustomObject]@{ Label = "Toggle Explorer Item Check Boxes" ; Action = { ExplorerTweaks -UpdateItemCheckBoxes } }
        [PSCustomObject]@{ Label = "Toggle Seconds on Clock" ; Action = { ToggleSecondsToClock } }
        [PSCustomObject]@{ Label = "Toggle Dark Mode" ; Action = { ToggleTheme } }
    )
}