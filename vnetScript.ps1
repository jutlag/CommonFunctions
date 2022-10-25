#action
$null = Update-AzConfig -DisplayBreakingChangeWarning $false
$ExcludedSubnets = @('GatewaySubnet','AzureFirewallSubnet','AzureFirewallManagementSubnet')
$virtualNetworks = Get-AzVirtualNetwork
$subnetsToFix = $virtualNetworks | Get-AzVirtualNetworkSubnetConfig | where {$_.NetworkSecurityGroup -eq $null -and $_.name -notin $ExcludedSubnets}
Write-host ("Number of subnets to fix {0}" -f $subnetsToFix.count)

foreach($subnetobj in $subnetsToFix){
    $subnetData = ($subnetobj.id).split('/')
    $resourceGroup = $subnetData[4]
    $vnetName = $subnetData[8]
    $vNetObj = $virtualNetworks | where {$_.Name -match $vnetName -and $_.ResourceGroupName -match $resourceGroup}
    $subnetName = $subnetData[10]
    if($subnetName -notin $ExcludedSubnets){
        $nsgName = ('NSG-{0}' -f $subnetName)
        Write-host $resourceGroup  $vnetName $subnetName $nsgName
        $networkSecurityGroupObj = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourcegroup -ErrorAction SilentlyContinue
        if(($null -eq $networkSecurityGroupObj) -or ($networkSecurityGroupObj.count -eq 0)){
            $networkSecurityGroupObj = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourcegroup -Location $vNetObj.Location
        }
        $null = Set-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vNetObj -NetworkSecurityGroupId $networkSecurityGroupObj.Id -AddressPrefix ($subnetobj.AddressPrefix)
        $null = $vNetObj | Set-AzVirtualNetwork
    }
}
