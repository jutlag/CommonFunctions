
Function New-DevopsProject {
 <#
  .SYNOPSIS

  Creates a New Powershell Devops Project

  .DESCRIPTION

  The function creates a set of powershell modules for a new Devops project. 
  This function creates a set of powershell modules with psd, psm, ps1 files
  including the unit test files. It creates a sample structure for functions 
  in each of the module to explain the interconnection and usage.

  I created this to kick start a new project without having to waste time setting
  up each module initially.

  .Notes
    Author: Gurpreet Singh Jutla 

  .EXAMPLE

  C:\PS> New-DevopsProject -ProjectName <Project Name> -Modules <Module1>, <Module2> -ProjectPath <projectPath> -CompanyName <Company Name> -Author <Author>
#>
 [CmdletBinding()]
 param (
  [Parameter(Mandatory = $true)]
  [String]$ProjectName,
  [Parameter(Mandatory = $true)]
  [String[]]$Modules,
  [Parameter(Mandatory = $true)]
  [String]$ProjectPath,
  [Parameter(Mandatory = $true)]
  [String]$CompanyName,
  [Parameter(Mandatory = $true)]
  [String]$Author,
  [Parameter(Mandatory = $false)]
  [String]$ProjectStartDate 
 )

 Process {

  if (-not (Test-Path -path $path)) {
   New-Item -Path $ProjectPath -Name $ProjectName -ItemType "directory"
  }

  if ([string]::IsNullOrEmpty( $ProjectStartDate)) {
   $ProjectStartDate = [String](Get-Date)
  }


  foreach ($module in $Modules) {
   $Folder = "$Project.$module"
   $file1 = "$Project-$module.psd1"
   $file2 = "$Project-$module.psm1"
   $file3 = "$Project-$module.tests.ps1"
   $file4 = "function-$module.tests.ps1"
   $file5 = "function-$module.ps1"
   $newguid = New-Guid
   $content = "<#==============================================================================================
Copyright(c) $companyName. All rights reserved.

File:		$file1

Purpose:	Project $projectName- Manifest for $module module

Version: 	1.0.0.0 - $projectStartDate  - Project $projectNameBuild Release Deployment Team
============================================================================================== #>
        
@{

  # Script module or binary module file associated with this manifest.
  RootModule        = '$file2'

  # Version number of this module.
  ModuleVersion     = '1.0'

  # ID used to uniquely identify this module
  GUID              = '$newguid'

  # Author of this module
  Author            = '$author'

  # Company or vendor of this module
  CompanyName       = '$companyName'

  # Copyright statement for this module
  Copyright         = '(c) 2018 $companyName. All rights reserved.'

  # Description of the functionality provided by this module
  Description       = 'Compute functions for $projectName deployment'

  # Minimum version of the Windows PowerShell engine required by this module
  PowerShellVersion = '5.0'

}"
   $content2 = "<#==============================================================================================
Copyright(c) $companyName. All rights reserved.

File:		 $file2

Purpose:	Project $ProjectName  - Export manifest for the $module module

Version: 	1.0.0.0 - $projectStartDate - Project $ProjectName Build Release Deployment Team
==============================================================================================
#>

<#
  .DESCRIPTION

  This file contains export statements for all public functions located in the imported script files.
#>
. `$PSScriptRoot\$file5

Export-ModuleMember -Function 'New-Dummy$Module'"
   $content3 = "#Unit/Pester tests for the $module module for $project"
   $content4 = "#Unit/Pester tests for the $module functions for $project"
   $content5 = "#Functional code for the $module module for $project
<#==============================================================================================
Copyright(c) $companyName. All rights reserved.

File:		function-$Module.ps1

Purpose:	Project $ProjectName - $Module Management

Version: 	1.0.0.0 - $projectStartDate - Project $ProjectName Build Release Deployment Team
==============================================================================================
#>

function New-Dummy$Module {
<#
  .SYNOPSIS

  Explain What this function does

  .DESCRIPTION

  Detailed Description of the function

  .EXAMPLE

  C:\PS> New-Dummy$Module -FirstVariable <'FirstVariableValue'>
#>
[CmdletBinding()]
Param (
  # Description about the FirstVariable
  [Parameter(Mandatory = `$true)]
  [string]`$FirstVariable
)

  begin {
    #Common Code for the Function here
  } process {
    #processing code for the Function Here
  } end {
    #Windup Code for the function
  }
}"

   Write-Host `$content
   New-Item -ItemType "Directory" -Path ($path ) -Name $folder
   New-Item -ItemType "File" -Path ($path + "\" + $Folder) -Name $file1
   New-Item -ItemType "File" -Path ($path + "\" + $Folder) -Name $file2
   New-Item -ItemType "File" -Path ($path + "\" + $Folder) -Name $file3
   New-Item -ItemType "File" -Path ($path + "\" + $Folder) -Name $file4
   New-Item -ItemType "File" -Path ($path + "\" + $Folder) -Name $file5
   Set-Content -Path ($path + "\" + $Folder + "\" + $file1) -Value $content
   Set-Content -Path ($path + "\" + $Folder + "\" + $file2) -Value $content2
   Set-Content -Path ($path + "\" + $Folder + "\" + $file3) -Value $content3
   Set-Content -Path ($path + "\" + $Folder + "\" + $file4) -Value $content4
   Set-Content -Path ($path + "\" + $Folder + "\" + $file5) -Value $content5
  }
 }
}

