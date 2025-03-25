function PreviewForegroundColors {
   return ([enum]::GetValues([System.ConsoleColor])) | ForEach-Object { Write-Host $_ -ForegroundColor $_ }
}

function RemoveByteOrderMark {
   param ( [string]$filePath )
   [System.IO.File]::WriteAllText($filePath, ((Get-Content -Path $filePath -Raw) -replace "^\xEF\xBB\xBF", ""), [System.Text.UTF8Encoding]::new($false))
}