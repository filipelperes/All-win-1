# Caminho do diretório do projeto
$projectPath = "$PSScriptRoot\..\..\"

# Caminho para salvar a estrutura em um arquivo de texto
$outputFilePath = "$projectPath\data\estrutura_projeto.txt"

# Função para obter a estrutura do diretório
function Get-DirectoryStructure {
   param (
      [string]$path,
      [int]$indentLevel = 0
   )

   $indent = " " * $indentLevel
   $items = Get-ChildItem -Path $path

   foreach ($item in $items) {
      if ($item.PSIsContainer) {
         "$indent|--- $($item.Name)\" | Out-File -FilePath $outputFilePath -Append -Encoding utf8
         Get-DirectoryStructure -path $item.FullName -indentLevel ($indentLevel + 4)
      }
      else {
         "$indent|--- $($item.Name)" | Out-File -FilePath $outputFilePath -Append -Encoding utf8
      }
   }
}

# Inicializa o arquivo de saída
"Windows Sync\" | Out-File -FilePath $outputFilePath -Encoding utf8

# Obtém a estrutura do diretório
Get-DirectoryStructure -path $projectPath -indentLevel 0

Write-Host "A estrutura do projeto foi extraída e salva em $outputFilePath" -ForegroundColor Green
