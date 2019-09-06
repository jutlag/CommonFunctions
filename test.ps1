$subscriptions = Get-azSubscription | Where-Object {$_.State -eq "Enabled"}
$currentContext = Get-AzContext
cls
$policyState = @()
foreach($subscription in $subscriptions){
    
    $null = Set-azContext $subscription
    $resources = Get-AzResource | Sort-object -Property ResourceGroupName
    
    foreach($resource in $Resources){
        $policiesAssigned = Get-AzPolicyState -ResourceId $Resource.id
        if($policiesAssigned.count -eq 0){
            $policyState += [PSCustomObject]@{  "Timestamp" = $null
                                                "PolicyAssignmentName" = $null
                                                "PolicyDefinitionName" = $null
                                                "PolicyDefinitionAction" = $null
                                                "PolicyDefinitionReferenceId" = $null
                                                "IsCompliant" = "Unknown"
                                                "Subscription" = $subscription.Name
                                                "SubscriptionID" = $subscription.id
                                                "ResourceName" = $Resource.Name
                                                "ResourceID" = $Resource.ID
                                                "ResourceType" = $Resource.Type
                                                "Total Policies" = $policiesAssigned.count
                                            }
        }
        else {
            $policyState += $policiesAssigned | Select-Object Timestamp, PolicyAssignmentName, PolicyDefinitionName, PolicyDefinitionAction, PolicyDefinitionReferenceId, IsCompliant , @{l="Subscription";e={$subscription.Name}}, @{l="SubscriptionID";e={$subscription.id}}, @{l="ResourceName";e={$Resource.Name}}, @{l="ResourceID";e={$Resource.ID}}, @{l="ResourceType";e={$Resource.Type}}, @{l="Total Policies";e={$policiesAssigned.count}}
        }
    }
    
}

$policyState | Export-csv C:\Users\A\Documents\policystate.csv -NoTypeInformation
