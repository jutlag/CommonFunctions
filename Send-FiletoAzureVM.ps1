Function Send-FiletoAzureVM{
<#
    .SYNOPSIS
      Send-FiletoAzureVM - Transfers a File and its content directly over to an Azure VM
    .DESCRIPTION
      Send-FiletoAzureVM - Transfers a File and its content directly over to an Azure VM 
    .EXAMPLE
    C:\PS> Send-FiletoAzureVM 
  #>
  [CmdletBinding()]
  Param (
    # The Azurre Virtual Machine to which the file needs to be trasneferred
    [Parameter(Mandatory = $True)]
    [string]$VMName,
    #Resource Group where the virtual machine exists
    [Parameter(Mandatory = $True)]
    [String]$ResourceGroup,
    #Full path to the file that needs to be transferred
    [Parameter(Mandatory = $True)]
    [String]$File,
    #Path on the target machine where the file needs to be copied
    [Parameter(Mandatory = $True)]
    [String]$TargetPath
  )
process {
        #Check if the source file exists, throw and exit if the file is not found
        if(Test-Path $file){
            Write-Verbose ("File '{0}' found" -f $file)
        }
        else{
            Throw "The file was not found and cannot be transffered to Azure VM"
        }

        #Get the Virtual machine object and its status
        $vmOBJ = Get-azVM -ResourceGroupName $ResourceGroup -Name $VMName -Status -ErrorAction SilentlyContinue

        #If the virtual machine could not be located throw an error and exit
        if($vmOBJ.count -eq 0){
            Throw ("The Virtual Mahine '{0}' does not exist in Resource Group '{1}'" -f $VMName, $ResourceGroup)
        }

        #Check the Status of the Virtuial machine. The file can be transferred only if the powerstate of the VM is running
        $vmStatus = ($vmObj.Statuses | Where-Object {$_.Code -match "Powerstate"}).DisplayStatus
        
        if($vmStatus -notmatch "running"){
            Write-Warning ("The virtual machine needs to be running. Current Status: '{0}'" -f $vmStatus)
            return
        }
        
        #Get the virtual machine object this time without status. 
        #If the Get-VM is run with -status it gets the status but not the details such as OS Type so we need to run the Get-azVM again
        $vmOBJ2 = Get-azVM -ResourceGroupName $ResourceGroup -Name $VMName -ErrorAction SilentlyContinue

        Write-Verbose $vmOBJ2.OSProfile 

        if($vmOBJ2.OSProfile.LinuxConfiguration){
            $TargetOSType = "Linux"
        }

        if($vmOBJ2.OSProfile.WindowsConfiguration){
            $TargetOSType = "Windows"
        }

        #Display verbose message about the OS type discovered
        Write-Verbose ("OS Type {0}" -f $TargetOSType)

        # check target path validity
        $filenameToCheck = $TargetPath

        # get invalid characters and escape them for use with RegEx
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
        $pattern = "[$illegal]"

        # find illegal characters
        $invalid = [regex]::Matches($filenameToCheck, $pattern, 'IgnoreCase').Value | Sort-Object -Unique 

        $hasInvalid = $invalid -ne $null
        if ($hasInvalid){
            #Ignore if target path has / and we are working with Linux path
            if(!($invalid -eq "/") -and ($TargetOSType -match "Linux")){
                throw "Target file path has illegal characters: $invalid"
            }

            #Ignore if target path has : and \ and we are working with Windows path
            if(!(($invalid -contains "\") -and ($invalid -contains ":")) -and ($TargetOSType -match "Windows")){
                throw "Target file path has illegal characters: $invalid"
            }
        }

        #If the target OS is Windows we need to transfer the file in a slightly different way
        if($TargetOSType -match "Windows"){
            #EXtract the file name from the full path
            $fileName = Split-Path $file -Leaf
            #Large files need to be broken down into smaller chunks.
            #Since the command line in powershell cannot hndle more than 8191 characters we will brealk the file in chunk of 5000 chars
            # I am using the chunk size as 5000 to make room for the target path and other data, it is safe to ssume tht the totl payload
            # in most circumstances would be less than 8191 - 5000
            $fileChunkSize = 5000
            
            #Read the entire file content and convert them to utf8 encoding and BAse 64, this also encodes file contents during transmit
            $content = ([Convert]::ToBase64String([System.Text.Encoding]::utf8.GetBytes((Get-Content -Path $file -Raw -Encoding Default))))

            #The payload handler is a script that must be run inside the target VM to convert the contents back and save them
            $payloadHandler = Join-path -Path "." -ChildPath "InVMScriptExecution.ps1"

            if(!(Test-path -Path $payloadHandler)){
                Throw "Payload handler for Windows VM was not found, it is essential to handle file upload to the VM"
            }

            #Check the Size of the file contents, it is smaller than the chunk size we can send the entire file in one go
            if($content.Length -lt $fileChunkSize){
                Write-Verbose ("File Smaller than {0} bytes" -f $fileChunkSize)
                
                #The file will not be appended and rather forced to be overwritten on target if Append is set to No
                $Append = "No"

                #Build the parameters to the payload handler so that the file can be creted on the trget
                $runcmdparameters=@{
                                        #Contents that need to be trnsfered to trget VM
                                        "Content" = $content;
                                        #File name on the target machine. It would be the same as on the source machine
                                        "FileName" = $fileName;
                                        # Target machine path where the file needs to be created
                                        "Path" = $TargetPath
                                        #Append mode for the file transfer
                                        "Append" = $Append
                                    }
                
                #Finally invoke the run command againt the VM to send the payload to the target VM
                Invoke-AzVMRunCommand `
                    -ResourceGroupName $ResourceGroup `
                    -VMName $VMName `
                    -CommandId RunPowerShellScript `
                    -ScriptPath $payloadHandler `
                    -Parameter $runcmdparameters `
                    -Verbose 
            }
            else{
                #If the file size is larger than our chunk size, split the contents into multiple chunks and send them one at a time
                Write-Verbose ("File Larger than {0} bytes" -f $fileChunkSize)
                #First chunk will be sending ppend s no to allow the file to be recreated if it already exist
                $Append = "No"
                
                #Initial counter 0
                $i=0
                while($i -le $content.length-$fileChunkSize){
                    $chunk=$true
                    #Get the content size equal to the file chunk size
                    $contentchunk = $content.substring($i, $fileChunkSize)
                    $runcmdparameters=@{
                                        "Content" = $contentchunk;
                                        #File name on the target machine. It would be the same as on the source machine
                                        "FileName" = $fileName;
                                        # Target machine path where the file needs to be created
                                        "Path" = $TargetPath
                                        #Append mode for the file transfer
                                        "Append" = $Append
                                    }
                
                    #Send Payload to the target VM
                    Invoke-AzVMRunCommand `
                        -ResourceGroupName $ResourceGroup `
                        -VMName $VMName `
                        -CommandId RunPowerShellScript `
                        -ScriptPath $payloadHandler `
                        -Parameter $runcmdparameters `
                        -Verbose
                    
                    #Increment counter to get the next valid chunk
                    $i += $fileChunkSize
                    
                    #if the file is being sent in chunks all new chunks after the first one should indicate append
                    $Append = "Yes"
                }

                #When the last chunk is remaining it needs to be sent too
                $contentchunk = $content.substring($i)

                $runcmdparameters=@{
                                        "Content" = $contentchunk;
                                        #File name on the target machine. It would be the same as on the source machine
                                        "FileName" = $fileName;
                                        # Target machine path where the file needs to be created
                                        "Path" = $TargetPath
                                        #Append mode for the file transfer
                                        "Append" = $Append
                                    }

                #Send the final chunk
                Invoke-AzVMRunCommand `
                    -ResourceGroupName $ResourceGroup `
                    -VMName $VMName `
                    -CommandId RunPowerShellScript `
                    -ScriptPath $payloadHandler `
                    -Parameter $runcmdparameters `
                    -Verbose
            }
        }

        #If the target VM is a Linux Machine, handle it differently
        if($TargetOSType -match "Linux"){

           #Get the filename from the full file name
           $fileName = Split-Path $file -Leaf

           #Get the raw content from the file
           $rawContent = Get-Content -Path $file -Raw 

           #Remove windows style line endings
           $Content = $rawContent.Replace("`r`n","`n")

           #Get the contents as utf8 and convert to Base64, this can be easily handled on the linux side with simple bash commands
           $EncodedText =[Convert]::ToBase64String([System.Text.Encoding]::utf8.GetBytes($Content))

           #This is now the Linux Payload handler file that will read the contents being sent over and construct the file on the other side
           $payloadHandler = Join-path -Path "." -ChildPath "InVMScriptExecution.sh"
           
           #The payload handler file must exist. throw an error if it doesnt
           if(!(Test-path -Path $payloadHandler)){
                Throw "Payload handler for Windows VM was not found, it is essential to handle file upload to the VM"
           }

           #Create the paremeters for the transfer
           $runcmdparameters = @{
                                    #Contents to be sent over
                                    param1 = $EncodedText; 
                                    #File name to be used for the file on the other side
                                    param2 = $fileName; 
                                    #Target Path where the file must be created
                                    param3 = $TargetPath 
                                }
           #Initiate the run command against the VM and display the result
           $result = Invoke-AzVMRunCommand `
                        -ResourceGroupName $ResourceGroup `
                        -VMName $VMName `
                        -CommandId RunShellScript `
                        -ScriptPath $payloadHandler `
                        -Parameter $runcmdparameters `
                        -Verbose

           Write-Output $result.Value[0].message
        }
    }
}
cls
Send-FiletoAzureVM -VMName templinuxvm -ResourceGroup templinuxrg -File C:\temp\temp2.txt -TargetPath /