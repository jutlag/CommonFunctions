function ConvertFrom-HtmlTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $htmlTable
    )
    Begin{
    function ConvertFrom-HtmlTableRow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $htmlTableRow
        ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        $headers
        ,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]$isHeader

    )
    process {
        $cols = $htmlTableRow | select -expandproperty td
        if($isHeader.IsPresent) {
            0..($cols.Count - 1) | %{$x=$cols[$_] | out-string; if(($x) -and ($x.Trim() -gt [string]::Empty)) {$x} else {("Column_{0:0000}" -f $_)}} #clean the headers to ensure each col has a name        
        } else {
            $colCount = ($cols | Measure-Object).Count - 1
            $result = new-object -TypeName PSObject
            0..$colCount | %{
                $colName = if($headers[$_]){$headers[$_]}else{("Column_{0:00000} -f $_")} #in case we have more columns than headers 
                $colValue = $cols[$_]
                $result | Add-Member NoteProperty $colName $colValue
            } 
            write-output $result
        }
    }
}
    }
    process {
        [xml]$cleanedHtml = ("<!DOCTYPE doctypeName [<!ENTITY nbsp '&#160;'>]><root>{0}</root>" -f ($htmlTable | select -ExpandProperty innerHTML | %{(($_ | out-string) -replace '(</?t[rdh])[^>]*(/?>)|(?:<[^>]*>)','$1$2') -replace '(</?)(?:th)([^>]*/?>)','$1td$2'})) 
        [string[]]$headers = $cleanedHtml.root.tr | select -first 1 | ConvertFrom-HtmlTableRow -isHeader
        if ($headers.Count -gt 0) {
            $cleanedHtml.root.tr | select -skip 1 | ConvertFrom-HtmlTableRow -Headers $headers | select $headers
        }
    }
}
