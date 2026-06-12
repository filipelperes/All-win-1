Set-StrictMode -Version Latest

$modulePath = Split-Path -Parent $PSScriptRoot
. "$modulePath\modules\utils\utils.ps1"

Describe "RemoveByteOrderMark" {
    It "removes BOM from UTF-8 with BOM file" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            # Write content with UTF-8 BOM (0xEF 0xBB 0xBF)
            $bom = [byte[]]@(0xEF, 0xBB, 0xBF, 0x48, 0x65, 0x6C, 0x6C, 0x6F) # "Hello" after BOM
            [System.IO.File]::WriteAllBytes($tempFile, $bom)

            RemoveByteOrderMark -filePath $tempFile

            $content = Get-Content -Path $tempFile -Raw
            $content | Should Be "Hello"
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force }
        }
    }

    It "does not modify file without BOM" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            [System.IO.File]::WriteAllText($tempFile, "World", [System.Text.UTF8Encoding]::new($false))

            RemoveByteOrderMark -filePath $tempFile

            $content = Get-Content -Path $tempFile -Raw
            $content.Trim() | Should Be "World"
        }
        finally {
            if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force }
        }
    }
}

Describe "Get-AsciiCode" {
    It "returns ASCII value for Escape key" {
        Get-AsciiCode -key Escape | Should Be 27
    }

    It "returns ASCII value for Enter key" {
        Get-AsciiCode -key Enter | Should Be 13
    }

    It "returns ASCII value for Space key" {
        Get-AsciiCode -key Spacebar | Should Be 32
    }
}
