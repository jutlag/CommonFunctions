function Replace-StringEscapeChars{
   [CmdletBinding()]
   param(
        [Parameter(Mandatory = $True, ValuefromPipeline = $True)]
        [String]$Inputstring

   )
   process{
    $dReplacements = @{
        "\\u003c" = "<"
        "\\u003e" = ">"
        "\\u0027" = "'"

    }

    foreach($oEnumerator in $dReplacements.GetEnumerator()){
        $Inputstring = $Inputstring -replace $oEnumerator.key, $oEnumerator.Value
    }
    return $Inputstring
   }

}