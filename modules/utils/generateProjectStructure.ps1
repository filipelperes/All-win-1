# Project directory path
$projectPath = "$PSScriptRoot\..\..\"

# Path to save the structure to a text file
$outputFilePath = "$projectPath\data\project_structure.txt"

# Function to get the directory structure
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

# Initialize the output file
"All-win-1\" | Out-File -FilePath $outputFilePath -Encoding utf8

# Get the directory structure
Get-DirectoryStructure -path $projectPath

Write-Host "Project structure extracted and saved to $outputFilePath" -ForegroundColor Green
