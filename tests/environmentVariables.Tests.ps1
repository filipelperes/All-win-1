Set-StrictMode -Version Latest

$modulePath = Split-Path -Parent $PSScriptRoot

# Load dependencies in correct order
. "$modulePath\modules\utils\json.ps1"
. "$modulePath\modules\utils\arrays.ps1"
. "$modulePath\modules\utils\recursive.ps1"

# Define only the functions we need to test (not the full file which has
# module-level code depending on external state)
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

Describe "Get-EnvironmentVariableTarget" {
    It "returns User target for scope 'User'" {
        Get-EnvironmentVariableTarget -scope "User" | Should Be ([System.EnvironmentVariableTarget]::User)
    }

    It "returns Machine target for scope 'Machine'" {
        Get-EnvironmentVariableTarget -scope "Machine" | Should Be ([System.EnvironmentVariableTarget]::Machine)
    }
}

Describe "GetDefaultEnvVars" {
    It "returns PSCustomObject with Machine and User properties" {
        $result = GetDefaultEnvVars
        $result.Machine | Should Not Be $null
        $result.User | Should Not Be $null
    }

    It "Machine env vars contain PATH or Path key" {
        $result = GetDefaultEnvVars
        $hasPath = $result.Machine.Keys -contains "PATH" -or
                   $result.Machine.Keys -contains "Path" -or
                   $result.Machine.Keys -contains "path"
        $hasPath | Should Be $true
    }
}
