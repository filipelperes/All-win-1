function Install-fnm { winget install --id "Schniz.fnm" --accept-package-agreements }
function Install-NVMForWindows { winget install --id "CoreyButler.NVMforWindows" --accept-package-agreements }
function Install-mise-en-place { winget install --id "jdx.mise" --accept-package-agreements }
function Install-PyenvForWindows {
   Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1" ; Remove-Item "./install-pyenv-win.ps1" -Force
}

function Install-Pnpm { Invoke-WebRequest "https://get.pnpm.io/install.ps1" -UseBasicParsing | Invoke-Expression }
function Install-Deno { Invoke-RestMethod "https://deno.land/install.ps1" | Invoke-Expression }
function Install-Bun { Invoke-RestMethod "bun.sh/install.ps1" | Invoke-Expression }
function Import-PipPackages { pip install (ArrayToString -array $global:pipPackages -separator " ") }

function Update-AllPipPackages {
   $outdatedPackages = pip list --outdated --format=json | ConvertFrom-Json

   Write-Host $("`n" * 6)

   foreach ($package in $outdatedPackages) {
      $name = $package.name
      Write-Host "Leveling up $name! XP gained!"
      pip install --upgrade $name
   }

   Write-Host "`nCongratulations! Your outdated packages are now just a memory." -ForegroundColor Green
}

function Import-GlobalNodePackages {
   $packages = ArrayToString -array $global:nodePackages -separator " "

   $importGlobalOptions = @(
      [PSCustomObject]@{ Label = "Using NPM" ; Action = { npm install --global $packages } }
      [PSCustomObject]@{ Label = "Using Yarn" ; Action = { yarn global add $packages } }
      [PSCustomObject]@{ Label = "Using PNPM" ; Action = { pnpm add -g $packages } }
   )

   Show-Menu -options $importGlobalOptions -title $null -submenu
}

<#
.SYNOPSIS
    Installs and configures Fish shell inside Git Bash on Windows.
.DESCRIPTION
    Orchestrates the full Fish-on-Git-Bash setup: dependencies, bash profile
    configuration, MSYS2 packages, Fish binaries, and optional winget packages.
#>
function Install-FishShellOnGitBash {
   if (-not (Test-WingetSupport)) {
      Write-Host "$global:space`Winget is not supported on this system." -ForegroundColor Yellow
      Start-Process "https://gist.github.com/filipelperes/212abbfd422b4f3c77a04a26f4729c4c"
      return
   }

   Install-GitBashDependencies
   $gitDir, $bashPath, $bashProfile, $bashRc = Get-GitBashPaths

   Initialize-BashFiles -bashProfile $bashProfile -bashRc $bashRc
   $bashProfileContent, $bashRcContent = Read-BashFiles -bashProfile $bashProfile -bashRc $bashRc

   $bashProfileContent, $bashRcContent = Set-BashProfileContent -bashProfileContent $bashProfileContent -bashRcContent $bashRcContent

   Write-Utf8File -Path $bashProfile -Content $bashProfileContent
   Write-Utf8File -Path $bashRc -Content $bashRcContent

   Invoke-GitBashCommand -bashPath $bashPath -command "source ~/.bash_profile; source ~/.bashrc"
   Install-Msys2BasePackages -bashPath $bashPath
   Install-Msys2FishPackage -gitDir $gitDir -bashPath $bashPath

   $bashRcContent = Enable-FishShellInBashRc -bashRc $bashRc
   Write-Utf8File -Path $bashRc -Content $bashRcContent

   Install-OptionalWingetPackages
}

# ─── helpers ─────────────────────────────────────────────────────────────────

function Install-GitBashDependencies {
   foreach ($id in @("Git.Git", "MSYS2.MSYS2")) {
      winget install --id $id --accept-package-agreements
   }
}

function Get-GitBashPaths {
   $gitDir = "$env:ProgramFiles\Git"
   $bashPath = "$gitDir\bin\bash.exe"
   $bashProfile = "$HOME\.bash_profile"
   $bashRc = "$HOME\.bashrc"
   return $gitDir, $bashPath, $bashProfile, $bashRc
}

function Initialize-BashFiles {
   param ($bashProfile, $bashRc)
   if (-not (Test-Path $bashProfile)) { New-Item -Path $bashProfile -ItemType File -Force | Out-Null }
   if (-not (Test-Path $bashRc))      { New-Item -Path $bashRc -ItemType File -Force | Out-Null }
}

function Read-BashFiles {
   param ($bashProfile, $bashRc)
   return (Get-Content -Path $bashProfile), (Get-Content -Path $bashRc)
}

function Write-Utf8File {
   param ([string]$Path, [string]$Content)
   [System.IO.File]::WriteAllText($Path, $Content, [System.Text.UTF8Encoding]::new($false))
   if ((Get-Content -Path $Path -Raw) -match "^\xEF\xBB\xBF") { RemoveByteOrderMark -filePath $Path }
}

function Set-BashProfileContent {
   param ([string[]]$bashProfileContent, [string[]]$bashRcContent)

   # Phase 1: ensure MSYS2 binaries are on PATH
   if ($bashProfileContent -notmatch "export PATH" -and $bashRcContent -notmatch "export PATH") {
      $bashProfileContent += "`nexport PATH=`"/c/msys64/usr/bin:`$PATH`""
   }
   else {
      $hasPathInProfile = $bashProfileContent -match "export PATH"
      $hasPathInRc      = $bashRcContent -match "export PATH"
      $msysInProfile    = $bashProfileContent -match "/c/msys64/usr/bin"
      $msysInRc         = $bashRcContent -match "/c/msys64/usr/bin"

      $pathReplacePattern = '(export PATH\s*=\s*")(.*?)(:?(\$PATH):?)?(.*?)(")'
      $msysPathInsert = '$1/c/msys64/usr/bin:${2:+$2}${5:+$5}${4:+:$4}$6'

      # Insert MSYS2 path into whichever file has the export but not the path yet
      if ($hasPathInProfile -and -not $msysInProfile) {
         $bashProfileContent = $bashProfileContent -replace $pathReplacePattern, $msysPathInsert
      }
      if ($hasPathInRc -and -not $msysInRc) {
         $bashRcContent = $bashRcContent -replace $pathReplacePattern, $msysPathInsert
      }
      # If neither has it and profile doesn't have export, add to rc (fallback handled above)
      if (-not $hasPathInProfile -and -not $msysInProfile -and $hasPathInRc -and -not $msysInRc) {
         $bashRcContent = $bashRcContent -replace $pathReplacePattern, $msysPathInsert
      }
   }

   # Phase 2: source bashrc from bash_profile
   if ($bashProfileContent -notmatch "source ~/.bashrc") {
      $bashProfileContent += "`n$(ArrayToString -array @( "if [ -f ~/.bashrc ] ; then", "   source ~/.bashrc", "fi") -separator "`n")"
   }

   # Phase 3: add useful alias
   if ($bashRcContent -notmatch "alias la") { $bashRcContent += "`nalias la='ls -la'" }

   return $bashProfileContent, $bashRcContent
}

function Invoke-GitBashCommand {
   param ([string]$bashPath, [string]$command)
   Start-Process -FilePath $bashPath -ArgumentList "-l", "-c", $command -Verb RunAs -Wait -WindowStyle Hidden
}

function Install-Msys2BasePackages {
   param ([string]$bashPath)
   Invoke-GitBashCommand -bashPath $bashPath -command "yes | pacman -S zstd ; yes | pacman -Syu"
}

function Install-Msys2FishPackage {
   param ([string]$gitDir, [string]$bashPath)

   $urls = @(
      "https://mirror.msys2.org/msys/x86_64/fish-3.7.1-3-x86_64.pkg.tar.zst"
      "https://mirror.msys2.org/msys/x86_64/libpcre2_16-10.45-1-x86_64.pkg.tar.zst"
   )

   foreach ($url in $urls) {
      $fileName = $url.Split("/")[-1].Trim()
      Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile "$gitDir\$fileName"
      Invoke-GitBashCommand -bashPath $bashPath -command "cd / ; tar --zstd -xf $fileName"
   }
}

function Enable-FishShellInBashRc {
   param ([string]$bashRc)
   $bashRcContent = Get-Content -Path $bashRc
   if ($bashRcContent -notmatch "exec fish") {
      $bashRcContent += "`n$(ArrayToString -array @("# Launch Fish", "if [ -t 1 ]; then", "exec fish", "fi") -separator "`n")"
   }
   return $bashRcContent
}

function Install-OptionalWingetPackages {
   $packages = @{
      "Starship.Starship"         = "Do you want Starship?"
      "Microsoft.WindowsTerminal" = "Do you want Windows Terminal?"
   }

   foreach ($id in $packages.Keys) {
      $packageInfo = winget list --id $id
      if ($packageInfo[-1] -eq "No installed package found matching input criteria.") {
         while (-not $install -or $install -notmatch $global:yesNoPattern) {
            $install = (Read-Host "$($packages[$id]) (yes/no)").Trim().ToLower()
            switch -Regex ($install) {
               $global:noPattern { break }
               $global:yesPattern {
                  winget install --id $id --accept-package-agreements
                  break
               }
            }
         }
      }
   }
}

function Install-Aider {
   while (-not $dependencies -or $dependencies -notmatch $global:yesNoPattern) {
      $dependencies = (Read-Host "Do you agree to install Python 3.12 if needed? (yes/no)").Trim().ToLower()
      switch -Regex ($dependencies) {
         $global:yesPattern { break }
         $global:noPattern { return }
      }
   }

   Set-ExecutionPolicy ByPass -Scope Process -Force
   Invoke-RestMethod "https://aider.chat/install.ps1" | Invoke-Expression
}

function Install-UV {
   winget install --id "astral-sh.uv" --accept-package-agreements
   # Set-ExecutionPolicy ByPass -Scope Process
   # Invoke-RestMethod "https://astral.sh/uv/install.ps1" | Invoke-Expression
}

function Install-Ruff {
   winget install --id "astral-sh.ruff" --accept-package-agreements
   # Set-ExecutionPolicy Bypass -Scope Process
   # Invoke-RestMethod "https://astral.sh/ruff/install.ps1" | Invoke-Expression
}

$nerdFontsMenu = [PSCustomObject]@{
   Description = "Nerd Fonts"
   Label       = "Nerd Fonts"
   Submenu     = @(
      [PSCustomObject]@{ Label = "Fira Code" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "fira-code", "fira-mono" } }
      [PSCustomObject]@{ Label = "Geist" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "geist-mono" } }
      [PSCustomObject]@{ Label = "Iosevka" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "iosevka", "iosevka-term", "iosevka-term-slab" } }
      [PSCustomObject]@{ Label = "JetBrains" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "jetbrains-mono" } }
      [PSCustomObject]@{ Label = "All" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest -UseBasicParsing "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "fira-code", "fira-mono", "geist-mono", "iosevka", "iosevka-term", "iosevka-term-slab", "jetbrains-mono" } }
   )
}

$4devsMenu = [PSCustomObject]@{
   Description = "4Devs"
   Label       = "4Devs"
   Submenu     = @(
      [PSCustomObject]@{ Label = "Install Aider" ; Action = { Install-Aider } }
      [PSCustomObject]@{ Label = "Install Ruff" ; Action = { Install-Ruff } }
      [PSCustomObject]@{ Label = "Install UV" ; Action = { Install-UV } }
      [PSCustomObject]@{ Label = "Import Global Node Packages" ; Action = { Import-GlobalNodePackages } }
      [PSCustomObject]@{ Label = "Import Pip Packages" ; Action = { Import-PipPackages } }
      [PSCustomObject]@{ Label = "Update All Pip Packages" ; Action = { Update-AllPipPackages } }
      [PSCustomObject]@{ Label = "Install Fast Node Manager (fnm)" ; Action = { Install-fnm } }
      [PSCustomObject]@{ Label = "Install mise-en-place" ; Action = { Install-mise-en-place } }
      [PSCustomObject]@{ Label = "Install NVM For Windows" ; Action = { Install-NVMForWindows } }
      [PSCustomObject]@{ Label = "Install pyenv for Windows" ; Action = { Install-PyenvForWindows } }
      [PSCustomObject]@{ Label = "Install Fish Shell On Git Bash" ; Action = { Install-FishShellOnGitBash } }
      [PSCustomObject]@{ Label = "Install Pnpm" ; Action = { Install-Pnpm } }
      [PSCustomObject]@{ Label = "Install Deno" ; Action = { Install-Deno } }
      [PSCustomObject]@{ Label = "Install Bun" ; Action = { Install-Bun } }
      $nerdFontsMenu
   )
}
