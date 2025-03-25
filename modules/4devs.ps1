. "$PSScriptRoot\utils\utils.ps1"

function Install-fnm { winget install --id "Schniz.fnm" --accept-package-agreements }
function Install-NVMForWindows { winget install --id "CoreyButler.NVMforWindows" --accept-package-agreements }
function Install-PyenvForWindows {
   Invoke-WebRequest -UseBasicParsing -Uri "https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1" -OutFile "./install-pyenv-win.ps1"; &"./install-pyenv-win.ps1"
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
   $importGlobalOptions = @(
      [PSCustomObject]@{ Label = "Using NPM" ; Action = { npm install --global (ArrayToString -array $global:nodePackages -separator " ") } }
      [PSCustomObject]@{ Label = "Using Yarn" ; Action = { yarn global add (ArrayToString -array $global:nodePackages -separator " ") } }
      [PSCustomObject]@{ Label = "Using PNPM" ; Action = { pnpm add -g (ArrayToString -array $global:nodePackages -separator " ") } }
   )

   Show-Menu -options $importGlobalOptions -titleName $null -submenu
}

function Install-FishShellOnGitBash {
   if (-not (checkWingetSupport)) {
      Write-Host "$global:space`Winget is not supported on this system." -ForegroundColor Yellow
      Start-Process "https://gist.github.com/filipelperes/212abbfd422b4f3c77a04a26f4729c4c"
      return
   }

   foreach ($id in @("Git.Git", "MSYS2.MSYS2")) { winget install --id $id --accept-package-agreements }

   $gitDir = "$env:ProgramFiles\Git"
   $bashPath = "$gitDir\bin\bash.exe"
   $bashProfile = "$HOME\.bash_profile"
   $bashRc = "$HOME\.bashrc"

   if (-not (Test-Path $bashProfile)) { New-Item -Path $bashProfile -ItemType File -Force | Out-Null }
   if (-not (Test-Path $bashRc)) { New-Item -Path $bashRc -ItemType File -Force | Out-Null }

   $bashProfileContent = Get-Content -Path $bashProfile
   $bashRcContent = Get-Content -Path $bashRc

   if ($bashProfileContent -notmatch "export PATH" -and $bashRcContent -notmatch "export PATH") { $bashProfileContent += "`nexport PATH=`"/c/msys64/usr/bin:`$PATH`"" }
   else {
      if (
         ($bashProfileContent -match "export PATH" -and $bashRcContent -match "export PATH" -and $bashProfileContent -notmatch "/c/msys64/usr/bin" -and $bashRcContent -notmatch "/c/msys64/usr/bin") -or
         ($bashRcContent -notmatch "export PATH" -and $bashProfileContent -match "export PATH" -and $bashProfileContent -notmatch "/c/msys64/usr/bin")
      ) { $bashProfileContent = $bashProfileContent -replace '(export PATH\s*=\s*")(.*?)(:?(\$PATH):?)?(.*?)(")', '$1/c/msys64/usr/bin:${2:+$2}${5:+$5}${4:+:$4}$6' }
      if ($bashProfileContent -notmatch "export PATH" -and $bashRcContent -match "export PATH" -and $bashRcContent -notmatch "/c/msys64/usr/bin") {
         $bashRcContent = $bashRcContent -replace '(export PATH\s*=\s*")(.*?)(:?(\$PATH):?)?(.*?)(")', '$1/c/msys64/usr/bin:${2:+$2}${5:+$5}${4:+:$4}$6'
      }
   }

   if ($bashProfileContent -notmatch "source ~/.bashrc") {
      $bashProfileContent += "`n$(ArrayToString -array @( "if [ -f ~/.bashrc ] ; then", "   source ~/.bashrc", "fi") -separator "`n")"
   }

   if ($bashRcContent -notmatch "alias la") { $bashRcContent += "`nalias la='ls -la'" }

   [System.IO.File]::WriteAllText($bashProfile, $bashProfileContent, [System.Text.UTF8Encoding]::new($false))
   if ((Get-Content -Path $bashProfile -Raw) -match "^\xEF\xBB\xBF") { RemoveByteOrderMark -filePath $bashProfile }

   [System.IO.File]::WriteAllText($bashRc, $bashRcContent, [System.Text.UTF8Encoding]::new($false))
   if ((Get-Content -Path $bashRc -Raw) -match "^\xEF\xBB\xBF") { RemoveByteOrderMark -filePath $bashRc }

   Start-Process -FilePath $bashPath -ArgumentList "-l", "-c", "`'source ~/.bash_profile; source ~/.bashrc`'" -Verb RunAs -Wait -WindowStyle Hidden
   Start-Process -FilePath $bashPath -ArgumentList "-l", "-c", "`'yes | pacman -S zstd ; yes | pacman -Syu`'" -Verb RunAs -Wait -WindowStyle Hidden
   #yes | pacman -S mingw-w64-ucrt-x86_64-gcc ; # open "MSYS2 UCRT64" from the Start menu and install the C and C++ compiler:
   #yes | pacman -S mingw-w64-clang-x86_64-clang ; # open "MSYS2 CLANG64" from the Start menu and install the C and C++ compiler:

   $urls = @(
      "https://mirror.msys2.org/msys/x86_64/fish-3.7.1-3-x86_64.pkg.tar.zst"
      "https://mirror.msys2.org/msys/x86_64/libpcre2_16-10.45-1-x86_64.pkg.tar.zst"
   )

   foreach ($url in $urls) {
      $fileName = $url.Split("/")[-1].Trim()
      Invoke-WebRequest -Uri $url -OutFile "$gitDir\$fileName"
      Start-Process -FilePath $bashPath -ArgumentList "-l", "-c", "`'cd / ; tar --zstd -xf $fileName`'" -Verb RunAs -Wait -WindowStyle Hidden
   }

   $bashRcContent = Get-Content -Path $bashRc

   if ($bashRcContent -notmatch "exec fish") {
      $bashRcContent += "`n$(ArrayToString -array @("# Launch Fish", "if [ -t 1 ]; then", "exec fish", "fi") -separator "`n")"
   }

   [System.IO.File]::WriteAllText($bashRc, $bashRcContent, [System.Text.UTF8Encoding]::new($false))
   if ((Get-Content -Path $bashRc -Raw) -match "^\xEF\xBB\xBF") { RemoveByteOrderMark -filePath $bashRc }

   $packages = @{
      "Starship.Starship"         = "Do you want Starship?"
      "Microsoft.WindowsTerminal" = "Do you want Windows Terminal?"
   }

   foreach ($id in $packages.Keys) {
      $packageInfo = winget list --id $id
      if ($packageInfo[-1] -eq "No installed package found matching input criteria.") {
         $install = Read-Host ($packages[$id])
         if ($install.Trim().ToLower() -in @("y", "yes", "s", "sim")) {
            winget install --id $id --accept-package-agreements
         }
      }
   }
}

$nerdFontsMenu = [PSCustomObject]@{
   Description = "Nerd Fonts"
   Label       = "Nerd Fonts"
   Submenu     = @(
      [PSCustomObject]@{ Label = "Fira Code" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "fira-code", "fira-mono" } }
      [PSCustomObject]@{ Label = "Geist" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "geist-mono" } }
      [PSCustomObject]@{ Label = "JetBrains" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "jetbrains-mono" } }
      [PSCustomObject]@{ Label = "All" ; Action = { & ([scriptblock]::Create((Invoke-WebRequest "https://to.loredo.me/Install-NerdFont.ps1"))) -Confirm:$false -Name "fira-code", "fira-mono", "geist-mono", "jetbrains-mono" } }
   )
}

$4devsMenu = [PSCustomObject]@{
   Description = "4Devs"
   Label       = "4Devs"
   Submenu     = @(
      [PSCustomObject]@{ Label = "Import Global Node Packages" ; Action = { Import-GlobalNodePackages } }
      [PSCustomObject]@{ Label = "Import Pip Packages" ; Action = { Import-PipPackages } }
      [PSCustomObject]@{ Label = "Update All Pip Packages" ; Action = { Update-AllPipPackages } }
      [PSCustomObject]@{ Label = "Install Fast Node Manager (fnm)" ; Action = { Install-fnm } }
      [PSCustomObject]@{ Label = "Install NVM For Windows" ; Action = { Install-NVMForWindows } }
      [PSCustomObject]@{ Label = "Install pyenv for Windows" ; Action = { Install-PyenvForWindows } }
      [PSCustomObject]@{ Label = "Install Fish Shell On Git Bash" ; Action = { Install-FishShellOnGitBash } }
      [PSCustomObject]@{ Label = "Install Pnpm" ; Action = { Install-Pnpm } }
      [PSCustomObject]@{ Label = "Install Deno" ; Action = { Install-Deno } }
      [PSCustomObject]@{ Label = "Install Bun" ; Action = { Install-Bun } }
      $nerdFontsMenu
   )
}
