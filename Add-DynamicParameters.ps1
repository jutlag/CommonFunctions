Function Add-DynamicParameters{
 <#
   .SYNOPSIS
 
     Add-DynamicParameters is a function which adds dynamic parameters based on the name value pair hashtable
 
   .DESCRIPTION
 
     Add-DynamicParameters is a function which adds dynamic parameters based on the name value pair hashtable
 
     .Notes
     Author: Gurpreet Singh Jutla 
 
   .EXAMPLE
 
   C:\PS> Add-DynamicParameters -parameterTable @{
         "ForeColor" = @{
                 Value = ([enum]::GetValues([System.ConsoleColor]))
                 IsMandatory = $false
             }
         "BGColor" =  @{
                 Value = ([enum]::GetValues([System.ConsoleColor]))
                 IsMandatory = $false
             }
     }
 
     In the above example the Add-DynamicParameters will create a dictionary collection of two parameters naming ForeColor and BG Color both having a set of
     system color collection. The IsMandatory field specifies if the parameter is mandatory or not
 #>
 [CmdletBinding()]
 param (
     [Parameter(Mandatory = $True)]
     [Hashtable]$parameterTable
  )
     #$colors  = [enum]::GetValues([System.ConsoleColor])
     $RuntimeParamDic  = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
     foreach($key in $parameterTable.keys){
         $ParamAttrib  = New-Object System.Management.Automation.ParameterAttribute
         $ParamAttrib.Mandatory  = $parameterTable[$key].IsMandatory
         $ParamAttrib.ParameterSetName  = '__AllParameterSets'
         $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
         $AttribColl.Add($ParamAttrib)
         $AttribColl.Add((New-Object System.Management.Automation.ValidateSetAttribute($parameterTable[$key].ValidateSet)))
         $RuntimeParam  = New-Object System.Management.Automation.RuntimeDefinedParameter($key,  [string], $AttribColl)
         $RuntimeParamDic.Add($key,  $RuntimeParam)
     }
     return  $RuntimeParamDic
 }
 
 
 #sample usage 
 function Test-DynamicValidateSet {
   [CmdletBinding()]
   param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Static1','Static2','Static3','Static4','Static5')]
    [String]$Test 
    
   )
   DynamicParam{          
      Add-DynamicParameters -parameterTable @{
          "ForeColor" = @{
                  ValidateSet = ([enum]::GetValues([System.ConsoleColor]))
                  IsMandatory = $false
              }
          "BGColor" =  @{
                  ValidateSet = ([enum]::GetValues([System.ConsoleColor]))
                  IsMandatory = $false
              }
      }
    }
   Process {
    Write-Host ("Test Parameter: {0}`nBGColor: {1}`nForecolor: {2}" -f $Test, $PSBoundParameters.BGColor, $PSBoundParameters.ForeColor)
   }
  }
  
  #Try the function and see what parameters are displayed
