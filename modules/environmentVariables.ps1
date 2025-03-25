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

function CheckRef { if (Test-Path -Path $envVarsFile) { return $true } else { return $false } }
function GetEnvironmentVariables { return GetJsonObject -fileName "environmentvariables" }

function EnvironmentVariableTarget {
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
        #Process = [System.Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]::Process)
    }
}

function GetRegEnvVars {
    $regEnvVars = [PSCustomObject]@{
        Machine = @{}
        User    = @{}
    }

    foreach ($item in $regEnvVars) {
        $prop = if ($item -like "HKLM*") { "Machine" } else { "User" }
        foreach ($i in ((Get-ItemProperty -Path $item).PSObject.Properties)) { $regEnvVars.$prop[$i.Name] = $i.Value }
    }

    return CompareBy $regEnvVars (GetDefaultEnvVars)
}

function GetVolatileEnvVars {
    $volatile = @{}
    foreach ($i in ((Get-ItemProperty -Path $volatileEnvpath).PSObject.Properties)) { $volatile[$i.Name] = $i.Value }
    return $volatile
}

function ModifyEnvironmentVariable {
    param (
        [string]$name,
        [string]$value,
        [switch]$remove,
        [ValidateSet("User", "Machine")][string]$scope = "User"
    )

    $value = if ($remove) { $null } else { $value }
    [System.Environment]::SetEnvironmentVariable($name, $value, (EnvironmentVariableTarget -scope $scope))
}

function GetEnvironmentVariable {
    param (
        [string]$name,
        [ValidateSet("User", "Machine")][string]$scope = "User"
    )

    $value = [System.Environment]::GetEnvironmentVariable($name, (EnvironmentVariableTarget -scope $scope))
    if ($null -ne $value) { return $value } else { return $null }
}

function RemoveRefValues {
    param ( $obj )

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )
        foreach ($i in (Get-IterableObject -obj $v)) {
            $ipair = GetItemKeyValuePair -item $i
            $ik = $ipair.Key
            $iv = $ipair.Value
            $obj.$k.$ik = $iv -replace ([regex]::Escape($data.ref.$k.$ik)), ''
        }
    }

    return $obj
}

function ExportEnvironmentVariables {
    param ( $from, $to )

    $data = GetEnvironmentVariables
    if (-not $data.personal) {
        $data | Add-Member -MemberType NoteProperty -Name personal -Value ( SortAll ( ReplaceAll -obj (GetDefaultEnvVars) -from $from -to $to ) )
        $data.personal.Machine.Path += ";"
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
    engaging -obj $toAdd -processItem {
        param ( $item, $k, $v )

        if (-not ((Get-IterableObject $v).Count -gt 0)) { continue }

        foreach ($i in (Get-IterableObject -obj $v)) {
            $ipair = GetItemKeyValuePair -item $i
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
    Label       = "Environment Variables"
    Submenu     = @(
        [PSCustomObject]@{ Label = "Backup/Export" ; Action = { ExportEnvironmentVariables -from $env:USERNAME -to "johndoe" } }
        [PSCustomObject]@{ Label = "Restore/Import" ; Action = { ImportEnvironmentVariables } }
    )
}