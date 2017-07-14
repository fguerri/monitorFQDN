###################################################################################################################
# UpdateNSG.ps1: This runbook examines all the NSG rules whose name end with the tag in param $monitoredRuleTag.
# Any rule referencing the IP address $oldIPAddress will be updated by replacing $oldIpAddress with $newIpAddress.
####################################################################################################################

# Input parameters
param (
    [Parameter(Mandatory=$true)][string]$oldIpAddress,
    [Parameter(Mandatory=$true)][string]$newIpAddress,
    [Parameter(Mandatory=$true)][string]$monitoredRuleTag
)

# Gets all the NSG's in all resource groups which are accessible by the current Azure account
$nsgs = Get-AzureRmNetworkSecurityGroup

# For each NSG ...
foreach ($g in $nsgs) {
    # ... get all the rules
    $rules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $g
    # For each rule...
    foreach ($r in $rules) {
        # if the rule is monitored by this script
        if ($r.Name.EndsWith($monitoredRuleTag)) {
            $ruleName = $r.Name 
            Write-Output ("UpdateNSG: Found monitored rule: $ruleName")
            # extract the source IP address for this rule
            $src = $r.SourceAddressPrefix
            if ($src.EndsWith("/32")) {
                $src = $src.Remove($src.IndexOf('/'))
            }
            # extract the destination IP address for this rule
            $dst = $r.DestinationAddressPrefix
            if ($dst.EndsWith("/32")) {
                $dst = $dst.Remove($dst.IndexOf('/'))
            }
            # if the rule references $oldIpAddress...
            if ($src -eq $oldIPAddress) {
                $res = Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $g `
                    -Name $r.Name `
                    -Priority $r.Priority `
                    -Direction $r.Direction `
                    -Protocol $r.Protocol `
                    -SourcePortRange $r.SourcePortRange `
                    -DestinationPortRange $r.DestinationPortRange `
                    -SourceAddressPrefix $newIpAddress `
                    -DestinationAddressPrefix $r.DestinationAddressPrefix`
                    -Access $r.Access     
                # update it with $newIpAddress                           
                Write-Output ("UpdateNSG: Updating rule...")
                $res = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $g

                Write-Output ("UpdateNSG: Updated source IP address from $oldIpAddress to $newIpAddress")
            }
            # if the rule references $oldIpAddress...
            elseif ($dst -eq $oldIPAddress) {
                $res = Set-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $g `
                    -Name $r.Name `
                    -Priority $r.Priority `
                    -Direction $r.Direction `
                    -Protocol $r.Protocol `
                    -SourcePortRange $r.SourcePortRange `
                    -DestinationPortRange $r.DestinationPortRange `
                    -SourceAddressPrefix $r.SourceAddressPrefix `
                    -DestinationAddressPrefix $newIpAddress `
                    -Access $r.Access 
                # update it with $newIpAddress                            
                Write-Output ("UpdateNSG: Updating rule...")
                $res = Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $g

                Write-Output ("UpdateNSG: Updated destination IP address from $oldIpAddress to $newIpAddress")
            }
            else {
                Write-Output ("UpdateNSG: No updates to this rule")
            }
        }
    }
}