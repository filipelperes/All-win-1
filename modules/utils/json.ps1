$script:dataCache = @{}

function GetJsonObject {
   param (
      [string]$fileName
   )

   if ($script:dataCache.ContainsKey($fileName)) {
      return $script:dataCache[$fileName]
   }

   $ps1Path = "$PSScriptRoot\..\..\data\$fileName.ps1"
   if (Test-Path -LiteralPath $ps1Path) {
      . $ps1Path
      $result = Get-Variable -Name "data_$fileName" -ValueOnly -ErrorAction Stop
   }
   else {
      $jsonPath = "$PSScriptRoot\..\..\data\$fileName.json"
      $result = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
   }

   $script:dataCache[$fileName] = $result
   return $result
}

function Clear-DataCache {
   $script:dataCache.Clear()
}

function ExportJson {
   param ( $data, $filePath )
   $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding utf8
}