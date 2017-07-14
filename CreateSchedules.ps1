param (
    
    # Name of the resource group that will contain the Automation account
    [Parameter(Mandatory=$true)]
    [string]$resGroupName,

    # Name of the Automation account (shown in the portal)
    [Parameter(Mandatory=$true)]
    [string]$automationAccountName,

    # Subscription Id
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    # Environemnt to log in to
    [Parameter(Mandatory=$false)]
    [ValidateSet("AzureCloud","AzureUSGovernment")]
    [string]$EnvironmentName="AzureCloud",

    # How frequently (minutes) to perform DNS resolution for monitored FQDN's
    [Parameter(Mandatory=$false)]
    [int]$pollingInterval = 5
)

Login-AzureRmAccount -EnvironmentName $EnvironmentName 
$Subscription = Select-AzureRmSubscription -SubscriptionId $SubscriptionId

$startTime = Get-date
$startTime = $startTime.AddMinutes(10)

for ($i=0; $i -lt 60; $i = $i+$pollingInterval) {
    $time = $startTime.AddMinutes($i)
    $schedule = New-AzureRmAutomationSchedule -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -Name "Hourly$i" -HourInterval 1 -StartTime $time
    Register-AzureRmAutomationScheduledRunbook -AutomationAccountName $automationAccountName -ResourceGroupName $resGroupName -RunbookName "MonitorFQDN" -ScheduleName $schedule.Name

}