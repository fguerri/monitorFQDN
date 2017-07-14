#Requires -RunAsAdministrator
# ==================================================================================================
# Paramters
# ==================================================================================================
param (
    # Name of the resource group that will contain the Automation account
    [Parameter(Mandatory=$true)]
    [string]$resGroupName,

    # Azure region to use
    [Parameter(Mandatory=$true)]
    [string]$resGroupLocation,

    # Subscription Id
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    # Environemnt to log in to
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [string]$EnvironmentName="AzureCloud",

    # Self-signed certificate password (needed for AzureRunAsAccount)
    [Parameter(Mandatory=$true)]
    [string]$password,

    # Name of the Automation account (shown in the portal)
    [Parameter(Mandatory=$true)]
    [string]$automationAccountName,

    # Pricing plan for the Automation account
    [Parameter(Mandatory=$false)]
    [ValidateSet("Free","Basic")]
    [string]$automationAccountPlan = "Free",

    # Comma-separated list of FQDN's to monitor
    [Parameter(Mandatory=$false)]
    [string]$monitoredFqdns = "<comma separated list of FQDNs to monitor>",

    # Comma- separated list of recipients that wil be notified if the database IP address changes
    [Parameter(Mandatory=$false)]
    [string]$recipients = "<comma separated list of email recipients>",

    # Email address that SendGrid will use to send messages. When notifications are sent, recipients will receive emails from this address
    [Parameter(Mandatory=$false)]
    [string]$sender = "<Sender name used by SendGrid>",

    # SendGrid Web API key. It must be generated in SendGrid's management portal
    [Parameter(Mandatory=$true)]
    [string]$sendGridApiKey,

    # Name suffix for NSG rules and UDR's to be monitored 
    [Parameter(Mandatory=$false)]
    [string]$monitoredRuleTag = "___MONITORED___"
)

# SendGrid Web API endpoint. Do not modify
$sendGridApiUrl = "https://api.sendgrid.com/v3/mail/send"

# ==================================================================================================
# End Paramters
# ==================================================================================================


# ==================================================================================================
# Script - DO NOT EDIT
# ==================================================================================================

Login-AzureRmAccount -EnvironmentName $EnvironmentName 
$Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId


New-AzureRmResourceGroup -Name $resGroupName -Location $resGroupLocation
New-AzureRmAutomationAccount -Name $automationAccountName -ResourceGroupName $resGroupName -Location $resGroupLocation -Plan $automationAccountPlan

New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "monitoredFqdns" -Value "$monitoredFqdns" -Encrypted $false -Description "Comma-separated list of FQDn's to monitor for IP address changes"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "monitoredIpAddresses" -Value "This variable will be automatically initialized in the first run" -Encrypted $false -Description "IP addresses resolved in the last run"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "recipients" -Value "$recipients" -Encrypted $false -Description "Comma-separated list of recipients' email adresses"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "sender" -Value "$sender" -Encrypted $false -Description "Email address that SendGrid will use as the sender"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "sendGridApiKey" -Value "$sendGridApiKey" -Encrypted $true -Description "SendGrid Web API key (generated in SendGrid's portal)"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "sendGridApiUrl" -Value "$sendGridApiUrl" -Encrypted $false -Description "SendGrid Web API endpoint"
New-AzureRmAutomationVariable -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "monitoredRuleTag" -Value "$monitoredRuleTag" -Encrypted $false -Description "Name suffix for NSG rules and UDR's to be monitored"


$runbooks = @(
    "MonitorFQDN",
    "AzureLogin",
    "SendMail",
    "UpdateNSG",
    "UpdateUDR"
)

$myPath = split-path $Script:MyInvocation.Mycommand.Path -Parent

foreach ($r in $runbooks) {
   $runbookPath = "$mypath\Runbooks\" + $r + ".ps1"
   $res = Import-AzureRmAutomationRunbook -Name $r -Type PowerShell -Path $runbookPath -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Published
}

$startTime = Get-date
$startTime = $startTime.AddMinutes(10)

cd "$myPath\RunAsAccount"
.\CreateAzureRunAsAccount.ps1 -ResourceGroup $resGroupName -AutomationAccountName $automationAccountName -SubscriptionId $subscriptionId -ApplicationDisplayName "MonitorFQDN" -SelfSignedCertPlainPassword $password -CreateClassicRunAsAccount $false


Write-Output ("Done! Please open your newly created Automation Account and:", "1. Update Azure Modules", "2. Import module AzureRM.Network", "3. Configure the account variables", "4. Run .\CreateSchedules.ps1 to automate execution")

# ==================================================================================================
# End script - DO NOT EDIT
# ==================================================================================================
