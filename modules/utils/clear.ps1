function Clear-DNS {
   Clear-DnsClientCache
}

function Clear-TempFiles {
   Remove-Item -Path $env:TEMP\* -Recurse -Force
}

function ClearHistory {
   Clear-History
}