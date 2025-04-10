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
      "{0}|---{1}{2}" -f $indent, $item.Name, $(if ($item.PSIsContainer) { "\" }) | Out-File -FilePath $outputFilePath -Append -Encoding utf8
      if ($item.PSIsContainer) { Get-DirectoryStructure -path $item.FullName -indentLevel ($indentLevel + 4) }
   }
}

# Inicializa o arquivo de saída
"Windows Sync\" | Out-File -FilePath $outputFilePath -Encoding utf8

# Obtém a estrutura do diretório
Get-DirectoryStructure -path $projectPath

Write-Host "A estrutura do projeto foi extraída e salva em $outputFilePath" -ForegroundColor Green
