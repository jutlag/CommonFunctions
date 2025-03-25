$DefaultDashes = 10
$dashes = (("=" * $DefaultDashes) -join "")
function Set-LogPath {
  <#
    .SYNOPSIS
  
    Set log file path
  
    .DESCRIPTION
  
    Set log file path
  
    .EXAMPLE
  
    C:\PS> Set-LogPath -FilePath <"path of logfile">
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $True)]
    [String]$FilePath 
  )
    process {
      #Set the environment variable for writing log file
      $env:Logfile = $FilePath 
    } 
}
function Write-Log {
  <#
    .SYNOPSIS
  
    Writes to a log file
  
    .DESCRIPTION
  
    Writes to a log file
  
    .EXAMPLE
  
    C:\PS> Write-Log -Type <optional> -Message "<message to write>"
  #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Information','Error', 'Warning')]
    [String]$Type = "Information",

    [Parameter(Position=0,Mandatory = $false)]
    [String]$Message = $dashes,

    [Parameter(Mandatory = $false)]
    [String]$FilePath = $env:Logfile,  #Use environment variable if it has been set for writing log file

    [Parameter(Mandatory = $false)]
    [String]$ShowOnHost = $env:ShowOnHost #Use environment variable if you want the messages on the console too
  )
    process {
      $timestamp = [string](Get-Date -Format "yyyy-MM-dd HH:mm:ss")
      #if no parameter has been passed and no environment variable exists, write log file in the local script path i.e. folder in which the scripts are being executed from.
      if([string]::IsNullOrEmpty($FilePath)){
        if([string]::IsNullOrEmpty($PSScriptRoot)){
            $folder = $env:TEMP
        }else{
          $folder = $PSScriptRoot
        }
        $FilePath = (Join-Path $folder -ChildPath "activity.log")
      }
      $outMessage = ("{0}: {1} - {2}" -f $timestamp, $type, $message) 
      $outMessage | Out-File -FilePath $FilePath -append

      #Depending on the value for Show on host and the color coding provided, write the error to the console device.
      if("True" -eq $ShowOnHost){
        switch ($type){
          "Error" {
            Write-Host -Message $outMessage -ForegroundColor Red
            break
          }
          "Warning" {
            Write-Host -Message $outMessage Yellow
            break
          }
          "Information" {
            Write-Host $outMessage -ForegroundColor Green
            break
          }
          Default {
            Write-Host $outMessage -ForegroundColor Green
          }
        }
      }
    } 
}
