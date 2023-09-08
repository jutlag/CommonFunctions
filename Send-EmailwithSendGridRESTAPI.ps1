function Send-EmailwithSendGridRESTAPI {
  <#
   .SYNOPSIS
         
     Send-EmailwithSendGridRESTAPI  Send email using SendGrid Rest API
         
   .DESCRIPTION
         
     Send-EmailwithSendGridRESTAPI  Send email using SendGrid Rest API
         
   .Notes
     Author: Gurpreet Singh Jutla 
     Source: https://lessergeekwebhosting.azurewebsites.net/2022/09/07/quicktip-sending-email-using-rest-api/ 

     Create a new sendgrid account and get the REST API TokenStringFromTwilio. Provide the token to make the REST API Call

     This function makes it easy to use the Send Grid API to send email. The code simplifies the REST API call documented
     on their public documentation. This code was first written by me in 2019 as a demonstration during my Free Azure
     training community session when I saw a student struggling to send email with attachment from his code running in 
     a virtual machine. I have delibrately removed the attachment piece from this code. You can reach out to me if you 
     fail to find that process to attach the email. 
         
   .EXAMPLE
         
   C:\PS>  Send-EmailwithSendGridRESTAPI -RecieverEmail <'gsjutla@lessergeek.com'> -RecieverDisplayName <'Gurpreet Singh Jutla'>
 #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)]
    [String] $RecieverEmail,  # You can also make this a string of arrays if you want multiple recipients.
    [Parameter(Mandatory = $True)]
    [String] $RecieverDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $SenderEmail,
    [Parameter(Mandatory = $True)]
    [String] $FromDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $BodyofEmail,  # You can pass the content as a HTML structure
    [Parameter(Mandatory = $True)]
    [String] $TokenStringFromTwilio,
    [Parameter(Mandatory = $True)]
    [String] $SubjectofEmail
  )
  Process {
    
    #Create Header for the REST API call.
    $Header = @{
      "authorization" = "Bearer $TokenStringFromTwilio"
    }
    $Body=@{
      "Personalizations" = @(
                               @{
                                  "To" = @(
                                           @{
                                              "email" = $RecieverEmail
                                              "name" = $RecieverDisplayName
                                            }
                                          )
                                  "Subject" = $SubjectofEmail
                                }
                            )
        "Content" = @(
                       @{
                         "Type" = "text/html"
                         "Value" = $BodyofEmail
                        }
                     )
         "From" = @{
                      "email" = $SenderEmail
                      "name" = $FromDisplayName
                   }
         }

    # Conver the body hash table value to json structure.
    $BodyJson = $Body | ConvertTo-Json -Depth 10

    #Parameters to Send the mail through Sendgrid
    $Parameters = @{
                    Method = "POST"
                    Uri = "https://api.sendgrid.com/v3/mail/send" # url of Sendgrid API
                    Headers = $Header
                    ContentType = "application/json"
                    Body = $BodyJson
                  }
    
    #Invoke REST API Call to Twilio sendgrid
    Invoke-RestMethod @Parameters       
  }
}
