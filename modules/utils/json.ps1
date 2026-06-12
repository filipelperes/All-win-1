function GetJsonObject {
   param (
      [string]$fileName
   )

   $ps1Path = "$PSScriptRoot\..\..\data\$fileName.ps1"
   if (Test-Path $ps1Path) {
      . $ps1Path
      return (Get-Variable -Name "data_$fileName" -ValueOnly -ErrorAction Stop)
   }

   return Get-Content -Path "$PSScriptRoot\..\..\data\$fileName.json" -Raw | ConvertFrom-Json
}

function ExportJson {
   param ( $data, $filePath )
   $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
}