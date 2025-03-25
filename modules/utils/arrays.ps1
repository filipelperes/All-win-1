function ArrayToString {
   param (
      [array]$array,
      [string]$separator
   )

   return $array -join $separator
}

function StringToArray {
   param (
      [string]$string,
      [string]$separator = " "
   )

   return $string -split $separator
}

function RemoveFromArray {
   param (
      [array]$array,
      [array]$props
   )

   return $array | Where-Object { $_ -notin $props }
}

function PrintArray {
   param (
      [array]$array,
      [int]$depth = 0
   )

   foreach ($i in $array) {
      if ($i -is [array] -or $i -is [object[]]) {
         Print-Array -array $i -depth ($depth + 1)
      }
      else {
         Write-Output ("{0}{1}" -f ("    " * $depth), $i)
      }
   }
}

function index {
   param ($array, $value)
   for ($i = 0; $i -lt $array.Count; $i++) {
      if ($array[$i] -match $value) { return $i }
   }
   return $null
}