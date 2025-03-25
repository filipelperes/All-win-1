. "$PSScriptRoot\modules\utils\json.ps1"

# Global for export and import of winget, scoop and chocolatey
$global:wingetJSONFileBkp = "$PSScriptRoot\data\backup\winget.json"
$global:chocoConfigFileBkp = "$PSScriptRoot\data\backup\chocolatey.config"
$global:scoopJSONFileBkp = "$PSScriptRoot\data\backup\scoop.json"

$global:nodePackages = (GetJsonObject -fileName "packages").Packages.Node
$global:pipPackages = (GetJsonObject -fileName "packages").Packages.Pip

# Do not remove or modify the following lines
$global:OSVersion = [System.Environment]::OSVersion.Version.Major
$global:OSBuild = [System.Environment]::OSVersion.Version.Build

$global:space = "`n" * 6