<# Modules for CompareBy, PrintOnScreen, RemoveBy #>
function IsIterable {
    param ($obj)
    return $obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary] -or $obj -is [PSCustomObject] -or $obj -is [array] -or $obj -is [object[]]
}

function IsNumber {
    param ($value)
    return $value -is [int] -or $value -is [long] -or $value -is [float] -or $value -is [double] -or $value -is [decimal]
}

function Get-IterableObject {
    param ($obj)

    if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { return $obj.GetEnumerator() }
    elseif ($obj -is [PSCustomObject]) { return $obj.PSObject.Properties }
    elseif ($obj -is [array] -or $obj -is [object[]] -or $obj -is [string] -or (IsNumber -value $obj)) { return $obj }
    else { return $null }
}

function Get-KeysValuesPair {
    param ($obj)

    if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { return @{ Keys = $obj.Keys; Values = $obj.Values } }
    elseif ($obj -is [PSCustomObject]) { return @{ Keys = $obj.PSObject.Properties.Name; Values = $obj.PSObject.Properties.Value } }
    else { return @{ Keys = $null; Values = $obj } }
}

function Get-Keys {
    param ($obj)

    if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { return $obj.Keys }
    elseif ($obj -is [PSCustomObject]) { return $obj.PSObject.Properties.Name }
    else { return $null }
}

function GetItemKeyValuePair {
    param ($item)

    switch ($item.GetType().Name) {
        "PSNoteProperty" { return @{ Key = $item.Name; Value = $item.Value } } #PSCustomObject
        "DictionaryEntry" { return @{ Key = $item.Key; Value = $item.Value } } #hashtable
        default { return @{ Key = $null; Value = $item } }
    }
}

function GetItemKey {
    param ($item)

    switch ($item.GetType().Name) {
        "PSNoteProperty" { return $item.Name } #PSCustomObject
        "DictionaryEntry" { return $item.Key } #hashtable
        default { return $null }
    }
}

function Get-KeyByValue {
    param ( $obj, $value )

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )
        if ($v -eq $value) { return $k }
    }
    return $null
}

function Get-Values {
    param ($obj)

    if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { return $obj.Values }
    elseif ($obj -is [PSCustomObject]) { return $obj.PSObject.Properties.Value }
    elseif ($obj -is [array] -or $obj -is [object[]] -or $obj -is [string] -or (IsNumber -value $obj)) { return $obj }
    else { return $null }
}

function GetItemValue {
    param ($item)

    if ($null -ne $item.GetType().Name -and $item.GetType().Name -in @("PSNoteProperty", "DictionaryEntry")) { return $item.Value }
    else { return $item }
}

function CreateResult {
    param ( $obj )

    if ($obj -is [PSCustomObject]) { return [PSCustomObject]@{} }
    elseif ($obj -is [hashtable]) { return @{} }
    elseif ($obj -is [System.Collections.Specialized.OrderedDictionary]) { return [ordered]@{} }
    elseif ($obj -is [array] -or $obj -is [object[]]) { return @() }
}

function Add-ToResult {
    param ( [ref]$result, $key, $value, $obj )

    if ($null -ne $key) {
        if ($obj -is [PSCustomObject]) { $result.Value | Add-Member -MemberType NoteProperty -Name $key -Value $value }
        else { $result.Value[$key] = $value }
    }
    else { $result.Value += @( $value ) }
}

function engaging {
    param (
        $obj,
        [scriptblock]$processItem
    )

    $aux = Get-IterableObject $obj
    if (-not $aux) { return }

    foreach ($item in $aux) {
        if (-not $item -or $item.GetType().Name -eq "PSProperty") { continue }  # LIÇÃO = PSProperty é as propriedades nativas como length, add, remove, ...
        $ipair = GetItemKeyValuePair $item
        $k = $ipair.Key
        $v = $ipair.Value
        & $processItem $item $k $v
    }
}

<#
    The CompareBy function recursively traverses heterogeneous objects, hashtables, and arrays, returning differences or similarities ($equals) of $input based on $ref depending on $equals:

    - Without compareBy or compareBy = "Default": returns differences/equalities of keys and values, prioritizing values.
    - compareBy = "Key": returns differences/equality of keys.
    - compareBy = "Value": returns differences/equality of values.
#>
function CompareBy {
    param (
        [ValidateSet("Default", "Key", "Value")][string]$by = "Default",
        [switch]$equals,
        $inputObj,
        $ref
    )

    return CompareByRecursive -by $by -equals:$equals -inputObj $inputObj -ref $ref
}

function CompareByRecursive {
    param ( $by, $equals, $inputObj, $ref )

    if ($null -eq $inputObj -or $null -eq $ref) { return }

    $opair = Get-KeysValuesPair -obj $ref
    $refKeys = $opair.Keys
    $refValues = $opair.Values

    if ($null -eq $refKeys -and $by -eq "Key") { return }

    $result = CreateResult $inputObj

    if ($null -eq $refKeys -and $by -in @("Value", "Default") -and ($inputObj -is [array] -or $inputObj -is [object[]])) {
        $result += $inputObj | Where-Object { if ($equals) { $_ -in $ref } else { $_ -notin $ref } }
    }
    else {
        engaging -obj $inputObj -processItem {
            param ( $item, $k, $v )

            $sub = if ((IsIterable -obj $v) -and ($k -in $refKeys)) {
                CompareByRecursive -by $by -equals:$equals -inputObj $v -ref $ref.$k
            }
            else { $null }

            $match = switch ($by) {
                "Key" { if ($equals) { $k -in $refKeys } else { $k -notin $refKeys } }
                "Value" { if ($equals) { $v -in $refValues } else { $v -notin $refValues } }
                "Default" { if ($equals) { $v -in $refValues -and $k -in $refKeys } else { $v -notin $refValues -or $k -notin $refKeys } }
            }

            if ($match -or $sub) {
                $value = if ( $null -ne $sub ) { $sub } elseif ( $null -ne $v ) { $v }
                Add-ToResult -result ([ref]$result) -key $k -value $value -obj $inputObj
            }
        }
    }

    return $result
}

<#
    The PrintOnScreen function recursively prints any type of data, with indentation to show the structure.
#>
function PrintOnScreen {
    param ( $obj )
    PrintOnScreenRecursive -obj $obj
}

function PrintOnScreenRecursive {
    param ( $obj, [int]$depth = 0 )

    if ($null -eq $obj) { return }

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )
        $indent = "    " * $depth

        Write-Output (
            "{0}{1}" -f
            $indent,
            $( if ($null -ne $k) { "$k = $v" } else { $v } )
            # "Item: {0}        Type: {1}`nName: {2}        Type: {3}`nKey: {4}        Type: {5}`nValue: {6}    Type: {7}`n`n" -f
            # $( if ($null -eq $item) { "null" } else { $item } ), $( if ($null -eq $item) { "null" } else { $item.GetType().Name } ),
            # $( if ($null -eq $item.Name) { "null" } else { $item.Name } ), $( if ($null -eq $item.Name) { "null" } else { $item.Name.GetType() } ),
            # $( if ($null -eq $item.Key) { "null" } else { $item.Key } ), $( if ($null -eq $item.Key) { "null" } else { $item.Key.GetType() } ),
            # $( if ($null -eq $item.Value) { "null" } else { $item.Value } ), $( if ($null -eq $item.Value) { "null" } else { $item.Value.GetType() } )
        )

        if (IsIterable -obj $v) { PrintOnScreenRecursive -obj $v -depth ($depth + 1) }
    }

    <#
    $aux = Get-IterableObject $obj
    if (-not $aux) { return }
    $aux | ForEach-Object {

        $ipair = GetItemKeyValuePair $_
        $k = $ipair.Key
        $v = $ipair.Value
        $indent = "    " * $depth

        Write-Output (
            "{0}{1}" -f
            $indent,
            $( if($null -ne $k) { "$k = $v" } else { $v } )
            #"Item: {0}        Type: {1}`nName: {2}        Type: {3}`nKey: {4}        Type: {5}`nValue: {6}    Type: {7}`n`n" -f
            #$( if ($null -eq $_) { "null" } else { $_ } ), $( if ($null -eq $_) { "null" } else { $_.GetType().Name } ),
            #$( if ($null -eq $_.Name) { "null" } else { $_.Name } ), $( if ($null -eq $_.Name) { "null" } else { $_.Name.GetType() } ),
            #$( if ($null -eq $_.Key) { "null" } else { $_.Key } ), $( if ($null -eq $_.Key) { "null" } else { $_.Key.GetType() } ),
            #$( if ($null -eq $_.Value) { "null" } else { $_.Value } ), $( if ($null -eq $_.Value) { "null" } else { $_.Value.GetType() } )
        )

        if(IsIterable -obj $v)  { PrintOnScreenRecursive -obj $v -depth ($depth + 1) }
    }
    #>
}

<#
    The RemoveBy function recursively traverses heterogeneous objects, hashmaps, and arrays and removes the keys/properties or values existing in $props depending on $removeBy:
    - $removeBy = "Key" (Default): removes keys/properties.
    - $removeBy = "Value": removes values.
#>
function RemoveBy {
    param (
        [ValidateSet("Key", "Value")][string]$removeBy = "Key",
        $obj,
        [string[]]$props
    )

    return RemoveByRecursive -obj $obj -props $props -removeBy $removeBy
}

function RemoveByRecursive {
    param ( $obj, $props, $removeBy )

    if ($null -eq $obj -or $null -eq $props -or $props.Count -eq 0) { return }

    $result = CreateResult $obj

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )

        $sub = if (IsIterable -obj $v) { RemoveByRecursive -obj $v -props $props -removeBy $removeBy } else { $null }

        $match = switch ($removeBy) {
            "Key" { $k -notin $props }
            "Value" { $v -notin $props }
        }

        if ($match -or $sub) {
            $value = if ( $null -ne $sub ) { $sub } elseif ( $null -ne $v ) { $v }
            Add-ToResult -result ([ref]$result) -key $k -value $value -obj $obj
        }
    }

    return $result
}

<#
    The GetCommonOrUnique function returns common or unique keys or values depending on the validateSet.
#>
function GetCommonOrUnique {
    param (
        [ValidateSet("Common", "Unique")][string]$search = "Common",
        [ValidateSet("Key", "Value")][string]$by = "Key",
        $inputObj,
        $ref
    )

    return GetCommonOrUniqueRecursive -search $search -by $by -inputObj $inputObj -ref $ref
}

function GetCommonOrUniqueRecursive {
    param ( $inputObj, $ref, $search, $by )

    if ($null -eq $inputObj -or $null -eq $ref) { return }

    $refPair = Get-KeysValuesPair -obj $ref
    $refKeys = $refPair.Keys
    $refValues = $refPair.Values

    if ($by -eq "Key" -and $null -eq $refKeys) { return }

    $result = [System.Collections.Generic.List[object]]::new()

    if ($null -eq $refKeys -and $by -eq "Value" -and ($inputObj -is [array] -or $inputObj -is [object[]])) {
        $result += $inputObj | Where-Object { if ($search -eq "Common") { $_ -in $ref } else { $_ -notin $ref } }
    }
    else {
        engaging -obj $inputObj -processItem {
            param ( $item, $k, $v )

            $sub = if ((IsIterable -obj $v) -and ($k -in $refKeys)) {
                GetCommonOrUniqueRecursive -search $search -by $by -inputObj $v -ref $ref.$k
            }
            else { $null }

            $match = switch ($by) {
                "Key" { if ($search -eq "Common") { $k -in $refKeys } else { $k -notin $refKeys } }
                "Value" { if ($search -eq "Common") { $v -in $refValues } else { $v -notin $refValues } }
            }

            if ($match -or $sub) {
                $value = if ( $null -ne $sub -and $null -ne $k) { @{ $k = $sub } }
                elseif ($null -ne $sub -and $null -eq $k) { $sub }
                elseif ( $by -eq "Key" -and $null -ne $k ) { $k }
                elseif ( $by -eq "Value" -and $null -ne $v ) { $v }

                $result.Add( $value )
            }
        }
    }

    return [object[]]$result
}

<#
    The GetAll function retrieves all keys or values depending on the validateSet.
#>
function GetAll {
    param (
        $obj,
        [ValidateSet("Key", "Value")][string]$by = "Key"
    )

    return GetAllRecursive -obj $obj -by $by
}

function GetAllRecursive {
    param ( $obj, $by )

    if ($null -eq $obj) { return }

    $result = [System.Collections.Generic.List[object]]::new()

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )

        $sub = if (IsIterable -obj $v) { GetAllRecursive -obj $v -by $by } else { $null }

        $value = if ( $null -ne $sub -and $null -ne $k ) { @{ $k = $sub } }
        elseif ( $null -ne $sub -and $null -eq $k ) { $sub }
        elseif ( $by -eq "Key" -and $null -ne $k ) { $k }
        elseif ( $by -eq "Value" -and $null -ne $v ) { $v }

        $result.Add($value)
    }

    return [object[]]$result
}

function ReplaceAll {
    param ( $obj, $from , $to )
    return ReplaceAllRecursive -obj $obj -from $from -to $to
}

function ReplaceAllRecursive {
    param ( $obj, $from, $to )

    if ($null -eq $obj -or $null -eq $from) { return }

    $result = CreateResult $obj

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )
        $sub = if (IsIterable -obj $v) { ReplaceAllRecursive -obj $v -from $from -to $to } else { $null }
        if ($v -is [string] -and $v -match $from) { $v = $v -replace $from, $to }
        $value = if ( $null -ne $sub ) { $sub } elseif ( $null -ne $v ) { $v } else { $item }
        Add-ToResult -result ([ref]$result) -key $k -value $value -obj $obj
    }

    return $result
}

function HashtableToPSCustomObject {
    param ( $obj )

    return HashtableToPSCustomObjectRecursive -obj $obj
}

function HashtableToPSCustomObjectRecursive {
    param ( $obj )

    $result = if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { [PSCustomObject]::new() }
    else { CreateResult -obj $obj }

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )
        $sub = if (IsIterable -obj $v) { HashtableToPSCustomObjectRecursive -obj $v } else { $null }
        $value = if ( $null -ne $sub ) { $sub } elseif ( $null -ne $v ) { $v }
        if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { $result | Add-Member -MemberType NoteProperty -Name $k -Value $value }
        else { Add-ToResult -result ([ref]$result) -key $k -value $value -obj $obj }
    }

    return $result
}

function SortAll {
    param (
        $obj,
        [ValidateSet("Asc", "Desc")][string]$order = "Asc"
    )

    return SortAllRecursive -obj $obj -order $order -depth 0
}

function SortAllRecursive {
    param ( $obj, $order, $depth )

    if ($null -eq $obj) { return }

    $result = CreateResult -obj $obj

    engaging -obj $obj -processItem {
        param ( $item, $k, $v )

        $sub = if (IsIterable -obj $v) { SortAllRecursive -obj $v -order $order -depth ($depth + 1) } else { $null }

        $v = if ($null -eq $sub) { $v }
        elseif ($sub -is [array] -or $sub -is [object[]]) { SortArrayOrObjectArray -array $sub -order $order }
        elseif ($sub -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { SortHashtable -hashtable $sub -order $order }
        elseif ($sub -is [PSCustomObject]) { SortPSCustomObject -obj $sub -order $order }

        Add-ToResult -result ([ref]$result) -key $k -value $v -obj $obj
    }

    if ($depth -eq 0) {
        if ($obj -is [array] -or $obj -is [object[]]) { return SortArrayOrObjectArray -array $result -order $order }
        if ($obj -is [hashtable] -or $obj -is [System.Collections.Specialized.OrderedDictionary]) { return SortHashtable -hashtable $result -order $order }
        if ($obj -is [PSCustomObject]) { return SortPSCustomObject -obj $result -order $order }
    }

    return $result
}

function SortArrayOrObjectArray {
    param ( $array, $order )
    return $array | Sort-Object -Descending:($order -eq "Desc")
}

function SortHashtable {
    param ( $hashtable, $order )
    $sortedHashtable = [ordered]@{}
    foreach ($i in ($hashtable.Keys | Sort-Object -Descending:($order -eq "Desc"))) { $sortedHashtable[$i] = $hashtable[$i] }
    return $sortedHashtable
}

function SortPSCustomObject {
    param ( $obj, $order )
    $sortedPSCustomObject = [PSCustomObject]::new()
    foreach ($i in ($obj.PSObject.Properties | Sort-Object Name -Descending:($order -eq "Desc"))) {
        $sortedPSCustomObject | Add-Member -MemberType NoteProperty -Name $i.Name -Value $i.Value
    }
    return $sortedPSCustomObject
}