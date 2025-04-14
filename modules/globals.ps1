$global:nodePackages = (GetJsonObject -fileName "packages").Packages.Node
$global:pipPackages = (GetJsonObject -fileName "packages").Packages.Pip

$global:OSVersion = [System.Environment]::OSVersion.Version.Major
$global:OSBuild = [System.Environment]::OSVersion.Version.Build

$global:yesNoPattern = "\b(y|s|n)[a-z]*\b"
$global:yesPattern = "\b(y|s)[a-z]*\b"
$global:noPattern = "\b(n)[a-z]*\b"

$global:space = "`n" * 6