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

function index {
   param ($array, $value)
   for ($i = 0; $i -lt $array.Count; $i++) {
      if ($array[$i] -match $value) { return $i }
   }
   return $null
}