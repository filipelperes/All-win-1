function ColorToolManager {
   param (
      [string]$colorToolUrl
   )
   $downloads = "$HOME\Downloads"
   $colorToolZip = "$downloads\ColorTool.zip"
   $colorToolDir = "$downloads\ColorTool"

   Invoke-WebRequest -Uri $colorToolUrl -OutFile $colorToolZip

   if (-not (Test-Path $colorToolDir)) { New-Item -Path $colorToolDir -ItemType Directory | Out-Null }

   Expand-Archive -Path $colorToolZip -DestinationPath $colorToolDir -Force

   $installCmdPath = "$colorToolDir\install.cmd"

   if (Test-Path -Path $installCmdPath) { Start-Process -FilePath "cmd.exe" -ArgumentList "/c $installCmdPath" -Verb RunAs -Wait -WindowStyle Hidden }

   Remove-Item -Path $colorToolZip, $colorToolDir -Recurse -Force
}

function Set-ConsoleFont {
   param (
      [string]$fontName
   )

   $fontFamily = switch ($fontName) {
      "Consolas" { 54 }
      "Lucida Console" { 49 }
      "Courier New" { 38 }
      "MS Gothic" { 48 }
      default { 0 }
   }

   foreach ($i in (Get-ChildItem -Path "HKCU:\Console" -ErrorAction SilentlyContinue)) {
      Set-ItemProperty -Path $i.PSPath -Name "FaceName" -Value $fontName
      Set-ItemProperty -Path $i.PSPath -Name "FontFamily" -Value $fontFamily
   }
}

function SetEnvVarCmdPrompt {
   param ( $prompt )
   $E = [char](Get-AsciiCode -key Escape)
   [Environment]::SetEnvironmentVariable('PROMPT', ($prompt -replace '\$E', $E), 'Process')
}

function Set-TitlebarColor {
   param ( [string]$color )

   $r = [convert]::ToInt32($color.Substring(1, 2), 16)
   $g = [convert]::ToInt32($color.Substring(3, 2), 16)
   $b = [convert]::ToInt32($color.Substring(5, 2), 16)

   $decColor = $r + ($g -shl 8) + ($b -shl 16)

   $paths = @(
      "HKCU:\Software\Microsoft\Windows\DWM"
      "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
   )

   Set-ItemProperty -Path $paths[0] -Name "AccentColor" -Value $decColor
   Set-ItemProperty -Path $paths[0] -Name "AccentColorInactive" -Value $decColor
   # Set-ItemProperty -Path $paths[1] -Name "ColorPrevalence" -Value 1
}

function Set-ConsoleTheme {
   param (
      [ValidateSet("Dracula")][string]$theme
   )

   switch ($theme) {
      "Dracula" {
         Install-PackageProvider -Name NuGet -Scope AllUsers
         Install-Module -Name PowerShellGet -Scope AllUsers
         Install-Module -Name posh-git -Scope AllUsers

         ColorToolManager -colorToolUrl "https://raw.githubusercontent.com/waf/dracula-cmd/master/dist/ColorTool.zip"

         $pwshCfgUrl = "https://raw.githubusercontent.com/dracula/powershell/refs/heads/master/theme/dracula-prompt-configuration.ps1"
         $pwshCfgName = $pwshCfgUrl.Split("/")[-1].Trim()
         Invoke-WebRequest -Uri $pwshCfgUrl -OutFile "$HOME\$pwshCfgName"
         $profileContent = Get-Content -Path $PROFILE -ErrorAction SilentlyContinue
         if (-not $profileContent -or $profileContent -notmatch ". `$HOME\$pwshCfgName") { Add-Content -Path $PROFILE -Value ". `$HOME\$pwshCfgName" }

         Set-ConsoleFont -fontName "Consolas"
         SetEnvVarCmdPrompt -prompt "$E[1;32;40m→ $E[1;36;40m$p$E[1;35;40m› $E[1;37;40m"
         Set-TitlebarColor -color "#262835"

         Write-Host @"
$("`n" * 3)
In Windows 10, the titlebar color can be set system-wide in Settings $( [char] 8594 ) Personalization $( [char] 8594 ) Colors $( [char] 8594 ) Custom color $( [char] 8594 ) More $( [char] 8594 ) #262835.

Right-click on the powershell title bar, then click Properties, then Colors, and change the screen background RGB to Red:38, Green:40, Blue:53.

Please restart the PowerShell window for the changes to take effect.

"@ -ForegroundColor Green
         Read-Host -Prompt "Press 'Enter' To Continue"
      }
   }
}

$pwshThemesMenu = if ($global:OSVersion -eq 10) {
   [PSCustomObject]@{
      Description = "Powershell Themes"
      Label       = "Powershell Themes"
      Submenu     = @(foreach ($i in @("Dracula")) {
            [PSCustomObject]@{
               Label  = "$i Theme Console"
               Action = { Set-ConsoleTheme -theme $i }
            }
         })
   }
}