function ConvertTo-HashTable {
 <#
  .SYNOPSIS

  Converts an object to HashTable

  .DESCRIPTION

  This function is written to convert an object such as PsObject to a valid HashTable.
  Since the function works recursively, it can convert nested objects to a valid Hashtable.
  It is particularly useful to read JSON files, ARM Templates, PsObjects to Hashtable to easily
  process and manage large structures in for loops etc. Usage will be demonstrated and explained 
  through some of the other examples in this repository.

  The function supports values from pipelines.

  .NOTES
  Credits: The original function was shared by Dave Wyatt in 2015 and I do not know if he was the
           original developer. However I improvised his code to replace Write-output and use 
           return instead as the write-output was interfering with my unit test code and some other
           code. Also I prefer using return over using write-output, write-host etc as return values
           from my functions. 
           Write-output with -Noenumerate gives the output data without enumerating values and simple
           return $collection in below code will return array values instead of the cobject, therefore
           I introduced the trick in the below line. There could be other ways but this one just works
           fine. Let me know if you have better ideas.
           Author: Unknown, Updated by Gurpreet Singh Jutla 

  .EXAMPLE

  C:\PS> Get-Content -path .\test.json | ConvertFrom-JSON | ConvertTo-HashTable
  C:\PS> ConvertTo-HashTable -InputObject <ValidJSONObject>
#>
 [CmdletBinding()]
 param (
  [Parameter(ValueFromPipeline)]
  $InputObject
 )

 process {
  if ($null -eq $InputObject) { return $null }

  if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
   $collection = @(
    foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
   )

   return @(,$collection)
  }
  elseif ($InputObject -is [psobject]) {
   $hash = @{ }

   foreach ($property in $InputObject.PSObject.Properties) {
    $hash[$property.Name] = ConvertTo-Hashtable $property.Value
   }

   return $hash
  }
  else {
   return $InputObject
  }
 }
}
