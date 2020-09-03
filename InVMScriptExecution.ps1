Param(  
  # Recieve the Content from the sender/commandline
  [parameter(Mandatory=$true)][String]$Content,
  # File name for the content to be saved in
  [parameter(Mandatory=$true)][String]$FileName,
  #Path where the file needs to be created
  [parameter(Mandatory=$true)][String]$Path,
  # File needs to be appended or forced overwritten
  [parameter(Mandatory=$false)][String]$Append
)
#Since the Boolean doesnt work very well with parameters from Invoke Command, convert yes/no to true/false
if($append.ToUpper() -eq "YES"){
    $toAppend = $true
}
else{
    $toAppend = $False
}

#Create the full file path to store the conent into
$fileObj = (Join-Path -Path $Path -ChildPath $FileName)

if($toAppend){
    Write-Host "Appending file"
    #Decode and store file content into a previously existing file
    [System.Text.Encoding]::utf8.GetString([System.Convert]::FromBase64String($Content)) | Out-File $fileObj -Append -Encoding default -NoNewline
}
else{
    Write-Host "Forcing file"
    #Decode and store file content into a file, overwrite the file if it already exists
    [System.Text.Encoding]::utf8.GetString([System.Convert]::FromBase64String($Content)) | Out-File $fileObj -Force -Encoding default -NoNewline
}

#Show the directory contents
Dir $path
#Check the target file size
(Get-Item -Path $fileObj).length
