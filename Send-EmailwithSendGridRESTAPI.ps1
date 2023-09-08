function Send-EmailwithSendGridRESTAPI {
  <#
   .SYNOPSIS
         
     Send-EmailwithSendGridRESTAPI  Send email using SendGrid Rest API
         
   .DESCRIPTION
         
     Send-EmailwithSendGridRESTAPI  Send email using SendGrid Rest API
         
   .Notes
     Author: Gurpreet Singh Jutla 
     Source: https://lessergeek.com/index.php/2022/09/07/quicktip-sending-email-using-rest-api/SubjectofEmail

     Create a new sendgrid account and get the REST API TokenStringFromTwilio. Provide the token to make the REST API Call

     This function makes it easy to use the Send Grid API to send email. The code simplifies the REST API call documented
     on their public documentation. 
         
   .EXAMPLE
         
   C:\PS>  Send-EmailwithSendGridRESTAPI -Path <'Stringtocheck'> 
 #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)]
    [String] $RecieverEmail,
    [Parameter(Mandatory = $True)]
    [String] $RecieverDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $SenderEmail,
    [Parameter(Mandatory = $True)]
    [String] $FromDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $BodyofEmail,
    [Parameter(Mandatory = $True)]
    [String] $TokenStringFromTwilio,
    [Parameter(Mandatory = $True)]
    [String] $SubjectofEmail
  )
  Process {
    
    #Create Header for the REST API call
    $Header = @{
      "authorization" = "Bearer $TokenStringFromTwilio"
    }
    $Body=@{
      "personalizations" = @(
                               @{
                                  "to" = @(
                                           @{
                                              "email" = $RecieverEmail
                                              "name" = $RecieverDisplayName
                                            }
                                          )
                                  "SubjectofEmail" = $SubjectofEmail
                                }
                            )
        "content" = @(
                       @{
                         "type" = "text/html"
                         "value" = $BodyofEmail
                        }
                     )
         "from" = @{
                      "email" = $SenderEmail
                      "name" = $FromDisplayName
                   }
         }

    $BodyJson = $Body | ConvertTo-Json -Depth 4


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
