function Send-SendGridEmail {
  <#
   .SYNOPSIS
         
     Send-SendGridEmail  Send email using SendGrid Rest API
         
   .DESCRIPTION
         
     Send-SendGridEmail  Send email using SendGrid Rest API
         
   .Notes
     Author: Gurpreet Singh Jutla 
     Source: https://lessergeek.com/index.php/2022/09/07/quicktip-sending-email-using-rest-api/

     Create a new sendgrid account and get the REST API token.
         
   .EXAMPLE
         
   C:\PS>  Send-SendGridEmail -Path <'Stringtocheck'> 
 #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True)]
    [String] $EmailTo,
    [Parameter(Mandatory = $True)]
    [String] $ToDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $EmailFrom,
    [Parameter(Mandatory = $True)]
    [String] $FromDisplayName,
    [Parameter(Mandatory = $True)]
    [String] $Content,
    [Parameter(Mandatory = $True)]
    [String] $Token,
    [Parameter(Mandatory = $True)]
    [String] $Subject
  )
  Process {
    $Body=@{
      "personalizations" = @(
                               @{
                                  "to" = @(
                                           @{
                                              "email" = $EmailTo
                                              "name" = $ToDisplayName
                                            }
                                          )
                                  "subject" = $Subject
                                }
                            )
        "content" = @(
                       @{
                         "type" = "text/html"
                         "value" = $Content
                        }
                     )
         "from" = @{
                      "email" = $EmailFrom
                      "name" = $FromDisplayName
                   }
         }

    $BodyJson = $Body | ConvertTo-Json -Depth 4
    $Header = @{
                  "authorization" = "Bearer $token"
                }

    #send the mail through Sendgrid
    $Parameters = @{
                    Method = "POST"
                    Uri = "https://api.sendgrid.com/v3/mail/send"
                    Headers = $Header
                    ContentType = "application/json"
                    Body = $BodyJson
                  }
    Invoke-RestMethod @Parameters       
  }
}
