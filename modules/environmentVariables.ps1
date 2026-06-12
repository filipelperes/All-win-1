. "$PSScriptRoot\utils\json.ps1"
. "$PSScriptRoot\utils\arrays.ps1"
. "$PSScriptRoot\utils\recursive.ps1"

$envVarsFile = "$PSScriptRoot\..\data\environmentvariables.json"
$volatileEnvpath = "HKCU:\Volatile Environment"
$envPath = @( "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "HKCU:\Environment")
$props = @(
    "NUMBER_OF_PROCESSORS"
    "OS"
    "PROCESSOR_ARCHITECTURE"
    "PROCESSOR_IDENTIFIER"
    "PROCESSOR_LEVEL"
    "PROCESSOR_REVISION"
    "OneDrive"
    "OneDriveConsumer"
)

function GetEnvironmentVariables { return GetJsonObject -fileName "environmentvariables" }

function Get-EnvironmentVariableTarget {
    param ( [string]$scope )

    switch ($scope) {
        "User" { return [System.EnvironmentVariableTarget]::User }
        "Machine" { return [System.EnvironmentVariableTarget]::Machine }
    }
}

function GetDefaultEnvVars {
    return [PSCustomObject]@{
        Machine = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Machine)
        User    = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::User)
    }
}

function ModifyEnvironmentVariable {
    param (
        [string]$name,
        [string]$value,
        [switch]$remove,
        [ValidateSet("User", "Machine")][string]$scope = "User"
    )

    $value = if ($remove) { $null } else { $value }
    [System.Environment]::SetEnvironmentVariable($name, $value, (Get-EnvironmentVariableTarget -scope $scope))
}

function GetEnvironmentVariable {
    param (
        [string]$name,
        [ValidateSet("User", "Machine")][string]$scope = "User"
    )

    $value = [System.Environment]::GetEnvironmentVariable($name, (Get-EnvironmentVariableTarget -scope $scope))
    if ($null -ne $value) { return $value } else { return $null }
}

function ExportEnvironmentVariables {
    param ( $from, $to )

    $data = GetEnvironmentVariables
    if (-not $data.personal) {
        $data | Add-Member -MemberType NoteProperty -Name personal -Value ( SortAll ( ReplaceAll -obj (GetDefaultEnvVars) -from $from -to $to ) )
        if ($data.personal.Machine.Path -notmatch ";$") { $data.personal.Machine.Path += ";" }
        if ($data.personal.User.Path -notmatch ";$") { $data.personal.User.Path += ";" }
    }

    ExportJson -data $data -filePath $envVarsFile
}

function ImportEnvironmentVariables {
    if (-not (GetEnvironmentVariables).personal) {
        Write-Host "$global:space`Alert: Personal environment variables have entered the multiverse. Current location unknown." -ForegroundColor Yellow
        return
    }

    $data = GetEnvironmentVariables
    $toAdd = ReplaceAll -obj (RemoveBy -obj (CompareBy -inputObj $data.personal -ref $data.ref) -props $props) -from "johndoe" -to $env:USERNAME
    Invoke-ObjectForEach -obj $toAdd -processItem {
        param ( $item, $k, $v )

        if (-not ((Get-IterableObject $v).Count -gt 0)) { continue }

        foreach ($i in (Get-IterableObject -obj $v)) {
            $ipair = Get-ItemKeyValuePair -item $i
            $ik = $ipair.Key
            $iv = $ipair.Value
            if ($ik -eq "Path") {
                $exist = GetEnvironmentVariable -name $ik -scope $k

                $existArray = StringToArray $exist -separator ";"
                $ivArray = StringToArray $iv -separator ";"

                #$iv = $iv -replace ([regex]::Escape($exist)), ''
                $iv = ArrayToString -array ($ivArray | Where-Object { $_ -notin $existArray }) -join ";"

                if ($exist -and $exist[-1] -ne ";") { $exist += ";" }
                if ($iv -and $iv[-1] -ne ";") { $iv += ";" }

                $value = $exist + $iv
            }
            else { $value = $iv }
            ModifyEnvironmentVariable -name $ik -value $value -scope $k
        }
    }
}

<#
. "$PSScriptRoot\..\data\backup\bkp.ps1"
$data | Add-Member -MemberType NoteProperty -Name "jenniffer" -Value (SortAll $jenniffer)
ExportJson -data $data -filePath $envVarsFile
#>

$environmentVariablesMenu = [PSCustomObject]@{
    Description = "Environment Variables"
    Label       = "Environment Variables (Experimental)"
    Submenu     = @(
        [PSCustomObject]@{ Label = "Backup/Export" ; Action = { ExportEnvironmentVariables -from $env:USERNAME -to "johndoe" } }
        [PSCustomObject]@{ Label = "Restore/Import" ; Action = { ImportEnvironmentVariables } }
    )
}