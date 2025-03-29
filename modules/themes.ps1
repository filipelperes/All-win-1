function Install-Windhawk { winget install --id "RamenSoftware.Windhawk" --accept-package-agreements }

function Install-SecureUxTheme {
   if (-not (CheckScoop)) {
      while (-not $dependencies -or $dependencies -notmatch $global:yesNoPattern) {
         $dependencies = (Read-Host "Do you agree to install scoop? (yes/no)").Trim().ToLower()
         switch -Regex ($dependencies) {
            $global:noPattern { return }
            $global:yesPattern {
               Install-Scoop
               break
            }
         }
      }
   }

   scoop bucket add extras
   scoop install secureuxtheme
}

$themesMenu = [PSCustomObject]@{
   Description = "Themes"
   Label       = "Themes"
   Submenu     = @(
      if ($global:OSVersion -eq 11) { [PSCustomObject]@{ Label = "Windhawk" ; Action = { Install-Windhawk } } }
      [PSCustomObject]@{ Label = "SecureUxTheme" ; Action = { Install-SecureUxTheme } }
   )
}