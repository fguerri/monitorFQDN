###################################################################################################################
# UpdateUDR.ps1: This runbook examines all the UDR's whose name end with the tag in param $monitoredRuleTag.
# Any rule referencing the IP address $oldIPAddress will be updated by replacing $oldIpAddress with $newIpAddress.
####################################################################################################################

# Input parameters
param (
    [Parameter(Mandatory=$true)][string]$oldIpAddress,
    [Parameter(Mandatory=$true)][string]$newIpAddress,
    [Parameter(Mandatory=$true)][string]$monitoredRuleTag
)


# Get all the Custom Route Tables accessible by the current Azure account
$tables = Get-AzureRmRouteTable
# For each table...
foreach ($t in $tables) {
    # For each route...
    foreach ($r in $t.Routes) {
        # if the route is monitored by this script
        if ($r.Name.EndsWith($monitoredRuleTag)) {
            $ruleName = $r.Name 
            Write-Output ("UpdateUDR: Found monitored rule: $ruleName")
            
            # Extract the prefix for this route
            $prefix = $r.AddressPrefix
            if ($prefix.EndsWith("/32")) {
                $prefix = $prefix.Remove($prefix.IndexOf('/'))
            }
            
            # If the prefix matches $oldIpAddress
            if ($prefix -eq $oldIPAddress) {
                $res = Set-AzureRmRouteConfig -RouteTable $t `
                    -Name $r.Name `
                    -AddressPrefix "$newIpAddress/32" `
                    -NextHopType $r.NextHopType `
                    -NextHopIpAddress $r.NextHopIpAddress `  
                
                # Update route by changing the prefix from $oldIpAddress to $newIpAddress                           
                Write-Output ("UpdateUDR: Updating rule...")
                $res = Set-AzureRmRouteTable -RouteTable $t

                Write-Output ("UpdateUDR: Updated address prefix from $oldIpAddress to $newIpAddress")
            } 
            else {
                Write-Output ("UpdateUDR: No updates to this rule")
            }
        }
    }
}