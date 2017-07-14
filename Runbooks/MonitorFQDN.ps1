#####################################################################################################
# MonitorFQDN.ps1: This runbook resolves the IP addresses for the FQDN's provided in $monitoredFqdns 
# and compares them to the IP addresses resolved in the previous run.
# If the IP address for an FQDN changes, child runbooks are invoked.
###################################################################################################### 

# Comma-separated list of IP addresses resolved in the previous run
$monitoredIpAddresses = Get-AutomationVariable -Name 'monitoredIpAddresses'

# Comma-separated list of FQDN's to monitor
$monitoredFqdns = Get-AutomationVariable -Name 'monitoredFqdns'

# Comma-separated list of FQDN's to monitor
$monitoredRuleTag = Get-AutomationVariable -Name 'monitoredRuleTag'


# Read list of FQDNs to be monitored from Automation variable of type "String"
# TrimEnd() removes trailing commas and semicolons
# Trim() removes blanks from each token (which contains exactly one FQDN) 
$monitoredFqdnsArray = $monitoredFqdns.TrimEnd(@(',',';')).Split(",;").Trim()

# Read list of IP addresses to which the monitored FQDNs have been resolved in the last run
# TrimEnd() removes trailing commas and semicolons
# Trim() removes blanks from each token (which contains exactly one FQDN) 
# variable $monitoredIpAddressesArray is explicitly initialized as an array
# This is needed to avoid it being implicitly assigned type "String" if only one FQDN is monitored
$monitoredIpAddressesArray = @($monitoredIpAddresses.TrimEnd(@(',',';')).Split(",;").Trim())

# Iterate through all the monitored FQDNs
$counter = 0
foreach ($fqdn in $monitoredFqdnsArray) { 
    write-output ("===== Monitored FQDN: $fqdn =====")
    # Initialize monitoredIpAddressesArray if it contains no elements
    if(!$monitoredIpAddressesArray[$counter]) {
        $monitoredIpAddressesArray += "0.0.0.0"
    }
    
    $lastIpAddress = $monitoredIpAddressesArray[$counter]

    # Resolve current FQDN
    $currentIpAddress = [system.net.dns]::GetHostByName("$fqdn").AddressList.IPAddressToString
    
    # Check if the IP has changed
    if (!$currentIPAddress.equals($lastIpAddress.toString())) {
        # The IP address changed since this script was last run
         write-output("IP address has changed. Old: $lastIpAddress New: $currentIpAddress")
        # Save the new IP Address
        $monitoredIpAddressesArray[$counter] = $currentIpAddress
       
        ################### Invoke child runbooks here ###################
        
        # sendMail runbook
        write-output("---> Invoking child runbook: SendMail")
        .\sendMail.ps1 -oldIpAddress $lastIpAddress -newIpAddress $currentIpAddress 
        
        # AzureLogin runbook
        write-output("---> Invoking child runbook: AzureLogin")
        .\AzureLogin.ps1

        # UpdateNSG runbook
        write-output("---> Invoking child runbook: updateNSG")
        .\updateNSG.ps1 -oldIpAddress $lastIpAddress -newIpAddress $currentIpAddress -monitoredRuleTag $monitoredRuleTag

        # UpdateUDR runbook
        write-output("---> Invoking child runbook: updateUDR")
        .\updateUDR.ps1 -oldIpAddress $lastIpAddress -newIpAddress $currentIpAddress -monitoredRuleTag $monitoredRuleTag

        ###################################################################
    
    } 
    else {
        # Nothing to do. Ip Address has not changed
        write-output("IP address has not changed. Current IP address is: $currentIpAddress")
    }
    # Advance counter for next iteration
    $counter++

    write-output ("", "")
}

# Persist IP addresses resolved in this run to Automation variable
$updatedIps = "";
foreach ($ip in $monitoredIpAddressesArray) {
    $updatedIps = $updatedIps + $ip + ";"
}

# Save the resolved IP addresses to automation variable (for next run)
Set-AutomationVariable -Name 'monitoredIpAddresses' -Value $updatedIps

write-output ("", "===== Done! =====")