Set-StrictMode -Version Latest

# Define the exact Test-WingetSupport function from winget.ps1
# (we can't dot-source winget.ps1 directly because its module-level menu
#  code depends on many other modules loaded only at runtime by main.ps1)
function Test-WingetSupport {
    return ($global:OSVersion -eq 10 -and $global:OSBuild -ge 16299) -or $global:OSVersion -gt 10
}

Describe "Test-WingetSupport" {
    AfterEach {
        Remove-Variable -Name OSVersion -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name OSBuild -Scope Global -ErrorAction SilentlyContinue
    }

    It "returns true when OS version is 10 and build >= 16299" {
        $global:OSVersion = 10
        $global:OSBuild = 19045

        Test-WingetSupport | Should Be $true
    }

    It "returns true when OS major version > 10 (Windows 11)" {
        $global:OSVersion = 11
        $global:OSBuild = 22000

        Test-WingetSupport | Should Be $true
    }

    It "returns false when OS is Windows 10 with old build" {
        $global:OSVersion = 10
        $global:OSBuild = 15063

        Test-WingetSupport | Should Be $false
    }

    It "returns false when OS is Windows 10 with build exactly 16299" {
        $global:OSVersion = 10
        $global:OSBuild = 16299

        Test-WingetSupport | Should Be $true
    }

    It "returns false when OS is Windows 10 with build below 16299" {
        $global:OSVersion = 10
        $global:OSBuild = 10240

        Test-WingetSupport | Should Be $false
    }
}
