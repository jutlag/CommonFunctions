
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

Function Set-AnyProcessAsCritical {
<#
  .SYNOPSIS

  Makes a process critical. Closing the process would cause the system to crash

  .DESCRIPTION

  This function is written to demonstrate the power of Powershell as a scripting language. 
  Please use this wisely, only for education purposes or for collecting a complete memory 
  dump when an application crash is needed along with kernel stacks or a complete memory dump.

  Please note that you will need to setup the registry key to generate a complete memory dump as I
  do not set that registry key explictly.

  .NOTES
  Credits: 
  Originally the Code was written by "Matthew Graeber", I just changed it to work with any process instead of the powershell process itself

  Read my article here 
  https://docs.microsoft.com/en-us/archive/blogs/ntdebugging/bugchecking-a-computer-on-a-usermode-application-crash

  .EXAMPLE

  C:\PS> Set-CriticalProcess
#>
[CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = 'High')] 
Param (
        #Crash system immediately by closingthe proces after making it a critical process
        [Switch]$ExitImmediatelyandCrash
)
DynamicParam{          
      Add-DynamicParameters -parameterTable @{
          "process" = @{
                  ValidateSet = (Get-process |  select @{l="Process";e={("{0} ({1})" -f $_.processname, $_.id)}}).Process
                  IsMandatory = $false
              }
      }
}
process {
        $processID = ($PSBoundParameters.process).split("(")[1].replace(")","")
    
        #Check if you are running powershell with administrative credentials
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw 'You must run Set-AnyProcessAsCritical from an elevated/Administartive PowerShell interface.'
        }

        $dynamicAssembly = New-Object System.Reflection.AssemblyName('BlueScreen')
        $assemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly($dynamicAssembly, [Reflection.Emit.AssemblyBuilderAccess]::Run)
        $moduleBuilder = $assemblyBuilder.DefineDynamicModule('BlueScreen', $False)
        $typeBuilder = $moduleBuilder.DefineType('BlueScreen.Win32.ntdll', 'Public, Class')

        $null = $typeBuilder.DefinePInvokeMethod('NtSetInformationProcess','ntdll.dll',
                                                        ([Reflection.MethodAttributes] 'Public, Static'),
                                                        [Reflection.CallingConventions]::Standard,
                                                        [Int32],
                                                        [Type[]] @([IntPtr], [UInt32], [IntPtr].MakeByRefType(), [UInt32]),
                                                        [Runtime.InteropServices.CallingConvention]::Winapi,
                                                        [Runtime.InteropServices.CharSet]::Auto)


        $ntdll = $typeBuilder.CreateType()
        $procObj = [Diagnostics.Process]::GetProcessById($ProcessID)
        $procHandle = $procObj.Handle
        $procName = $procObj.ProcessName
        $returnPtr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal(4)
        $processBreakOnTermination = 29
        $sizeUInt32 = 4

        try{
            $null = $ntdll::NtSetInformationProcess($procHandle, $processBreakOnTermination, [Ref] $returnPtr, $sizeUInt32)
        }
        catch {
		    Write-Host ("Process '{0}' with id: '{1}' could not be marked as a critical process" -f $procName, $ProcessID)
            return
        }

        Write-Host ("Process '{0}' with id: '{1}' is now marked as a critical process and will blue screen the machine upon exiting the process." -f $procName, $ProcessID)

        if ($ExitImmediately){
            Stop-Process -Id $PID
        }

    }
}