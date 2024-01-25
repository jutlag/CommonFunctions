function New-SimpleISOFile {  
<#
  .SYNOPSIS

  Creates a Simple ISO file (Non Bootable) with contents from a folder specified

  .DESCRIPTION

  Often you might need to transfer contents to a system where the copy and paste does not work. Or you want to run commands against a virtual machine. 
  For example ILO/DRAC etc. If there too many commands to type you may wish to put files in a ISo file and attach that ISO to the system and then open
  the file in notepad, simply copy the commands from the content in an iso file and execute them. You might want to transfer large files from a host and
  RDP isnt available but you have the ability to mount an ISO, this script can prove handy. Simply specify the source folder and the ISO path where the 
  ISO needs to be created.

  For a code to create a Bootable ISO file, please email gsjutla@lessergeek.com

  .EXAMPLE

  C:\PS> New-SimpleISOFile -SourceFolder <Folder to create ISO from> -ISOPAth <Target path for ISO>
#>
  [CmdletBinding()]
  Param( 
    [parameter(Position=1,Mandatory=$true)]$SourceFolder,  
    [parameter(Position=2)][string]$ISOPath = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso" 
  )
($compilerParamater = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
Add-Type -CompilerParameters $compilerParamater -TypeDefinition @'
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
   
    if (o != null) { 
      while (TotalBlocks-- > 0) { i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);}  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  

$Target = New-Item -Path $ISOPath -ItemType File
($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=([string]((Get-Date).ToString("yyyyMMdd-HHmmss.ffff")))}).ChooseImageDefaultsForMediaType(13) 

foreach($item in $SourceFolder) { 
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { $item = Get-Item -LiteralPath $item  } 
      if($item) { $Image.Root.AddTree($item.FullName, $true)  } 
}

$Result = $Image.CreateResultImage()  
[ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks) 
Write-Host "Target image '($($Target.FullName))' has been created"
}
