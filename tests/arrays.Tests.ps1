Set-StrictMode -Version Latest

$modulePath = Split-Path -Parent $PSScriptRoot
. "$modulePath\modules\utils\arrays.ps1"

Describe "ArrayToString" {
    It "joins array elements with separator" {
        ArrayToString -array @("a", "b", "c") -separator "," | Should Be "a,b,c"
    }

    It "handles single-element array" {
        ArrayToString -array @("only") -separator "," | Should Be "only"
    }

    It "handles empty array" {
        ArrayToString -array @() -separator "," | Should Be ""
    }

    It "uses space separator correctly" {
        ArrayToString -array @("x", "y") -separator " " | Should Be "x y"
    }
}

Describe "StringToArray" {
    It "splits string by default space separator" {
        $result = StringToArray -string "a b c"
        $result.Count | Should Be 3
        $result[0] | Should Be "a"
        $result[1] | Should Be "b"
        $result[2] | Should Be "c"
    }

    It "splits by custom separator" {
        $result = StringToArray -string "x;y;z" -separator ";"
        $result.Count | Should Be 3
        $result[0] | Should Be "x"
    }

    It "handles single-item string" {
        $result = StringToArray -string "single" -separator ","
        $result | Should Be "single"
    }

    It "handles empty string" {
        $result = StringToArray -string "" -separator ","
        $result | Should Be ""
    }
}

Describe "Get-Index" {
    It "finds matching value by regex" {
        $array = @("apple", "banana", "cherry")
        Get-Index -array $array -value "nana" | Should Be 1
    }

    It "returns 0 for first element match" {
        $array = @("alpha", "beta", "gamma")
        Get-Index -array $array -value "^alpha" | Should Be 0
    }

    It "returns null when no match" {
        $array = @("one", "two", "three")
        Get-Index -array $array -value "four" | Should Be $null
    }

    It "returns last index for last element" {
        $array = @("cat", "dog", "fish")
        Get-Index -array $array -value "fish" | Should Be 2
    }

    It "handles empty array" {
        Get-Index -array @() -value "anything" | Should Be $null
    }
}
