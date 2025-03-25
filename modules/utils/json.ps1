function GetJsonObject {
   param (
      [string]$fileName
   )

   return Get-Content -Path "$PSScriptRoot\..\..\data\$fileName.json" -Raw | ConvertFrom-Json
}

function ExportJson {
   param ( $data, $filePath )
   $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
}