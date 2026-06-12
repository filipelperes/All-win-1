Set-StrictMode -Version Latest

$modulePath = Split-Path -Parent $PSScriptRoot

Describe "GetJsonObject" {
    It "loads a valid .ps1 data file by name" {
        . "$modulePath\modules\utils\json.ps1"
        $result = GetJsonObject -fileName "packages"
        $result.Packages | Should Not Be $null
        $result.Packages.Node | Should Not Be $null
    }

    It "returns cached result on second call" {
        . "$modulePath\modules\utils\json.ps1"
        # Force clear cache first
        $script:dataCache.Clear()
        $first = GetJsonObject -fileName "packages"
        $second = GetJsonObject -fileName "packages"
        $first | Should Be $second
    }

    It "forces reload when -Force is used" {
        . "$modulePath\modules\utils\json.ps1"
        $script:dataCache.Clear()
        $first = GetJsonObject -fileName "packages"
        $script:dataCache.Clear()
        $second = GetJsonObject -fileName "packages" -Force
        $first.Packages.Node.Count | Should Be $second.Packages.Node.Count
    }
}

Describe "ExportJson" {
    It "exports data to JSON file without error" {
        . "$modulePath\modules\utils\json.ps1"

        $testData = [PSCustomObject]@{ Name = "Test"; Value = 42 }
        $tempFile = [System.IO.Path]::GetTempFileName()

        { ExportJson -data $testData -filePath $tempFile } | Should Not Throw

        $content = Get-Content -Path $tempFile -Raw | ConvertFrom-Json
        $content.Name | Should Be "Test"
        $content.Value | Should Be 42

        Remove-Item -Path $tempFile -Force
    }

    It "exports empty object" {
        . "$modulePath\modules\utils\json.ps1"

        $testData = [PSCustomObject]@{}
        $tempFile = [System.IO.Path]::GetTempFileName()

        { ExportJson -data $testData -filePath $tempFile } | Should Not Throw

        Remove-Item -Path $tempFile -Force
    }
}
