#========================== Copy lines below this line  ==========================

#Azure Subscription/Tenant, Application and secret to fetch the data
#========= Warning !!! - TAS CONfidential Information below - Do not share outside TAS
        $subscriptionId = "2de9c9db-8929-4a51-a5e8-64a6330c6fb9"
        $tenantId       = "36446030-d1e1-43e7-9e9e-f885a754ae2f" 
        $clientID       = "2673fc27-aa16-4825-951f-51a82b4f5641"      
        $clientSecret   = "SYuT_o88e6V2.vDpf6.-6-BlfhmFc16~N6"  

    #Connecting to the log analytics workspace  using its global unique id
        $WorkspaceId = "0363abfe-1651-4edc-9096-72cb14fb79d3"
#========= Warning !!! - TAS CONfidential Information above  - Do not share outside TAS

#Authorization URl to build an Auth token
$loginURL       = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$resource       = "https://api.loganalytics.io"         
$body           = @{
                        grant_type    = "client_credentials";
                        resource      = $resource;
                        client_id     = $clientID;
                        client_secret = $clientSecret
                   }

#Authentication call
$oauth          = Invoke-RestMethod -Method Post -Uri $loginURL -Body $body

#Building header using the access token
$header = @{
                    Authorization = "$($oauth.token_type) $($oauth.access_token)"
           }


$uri = "https://api.loganalytics.io/v1/workspaces/$WorkspaceId/query"

#A formatted kusto query that will fetch the data,
$bodyHash = @{ 
                query = 'SecurityIncident | where TimeGenerated > ago(7d)'
             } 

#We will send a body in Rest API call in JSON format hence the conversion         
$body =  $bodyHash | ConvertTo-Json

#Make Rest API call and store result in the variable
$result = Invoke-RestMethod -UseBasicParsing -Headers $header -Uri $uri -Method Post -Body $body -ContentType "application/json"

#Check the number of log entries recieved from REST API call
$result.tables[0].rows.Count

#Convert data to a tabular format that can be used for CSV export
$headerRow = $null
$headerRow = $result.tables.columns | Select-Object name
$columnsCount = $headerRow.Count

$logData = @()

foreach ($row in $result.tables.rows) {
    $data = new-object PSObject
    for ($i = 0; $i -lt $columnsCount; $i++) {
        $data | add-member -membertype NoteProperty -name $headerRow[$i].name -value $row[$i]
    }
    $logData += $data
    $data = $null
}

# Export to CSV
$csvPath = (Join-path -path $env:TEMP -ChildPath "loganalyticsresult.csv")
$logData | export-csv -path $csvPath -NoTypeInformation

#Open file in Excel
Invoke-Item $csvPath

#========================== Copy lines above this line  ==========================
