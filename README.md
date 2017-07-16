#MonitorFQDN
MonitorFQDN is an Azure Automation solution that monitors a list of FQDN's (Fully Qualified Domanin Names) for IP address changes. Every time an FQDN is resolved to a different IP address than the one resolved in the previous run, one or more runbooks are invoked, in order to:

1) Send email notifications about the IP address changes;
2) Update Azure NSG (Network Security Group) rules that reference the IP address that has changed;
3) Update Azure UDR's (User Defined Routes) that reference the IP address that has changed.

MonitorFQDN uses an Azure "RunAs" account to log into your subscription(s) and searches through all the available NSG's and UDR's. MonitorFQDN only manages the rules whose name ends with a configurable suffix (by defualt, "\_\_\_MONITORED\_\_\_").

This repository contains the following files:
- __CreateAutomationAccount.ps1__: Installation script. It creates the Automation Account and the required runbooks and assets.
-  __CreateSchedules.ps1__: Post-Installation script to create schedules and automate exceution.
-  __README.md__: This file.
-  __RunAsAccount\CreateAzureRunAsAccount.ps1__: Helper script that proovides functions to create the Azure RunAs Account in your Automation account.
-  __Runbooks\MonitorFQDN.ps1__: Main runbook. It resolves FQDNs and maintains the list of the corresponding IP addresses. When needed, it invokes child runbooks.
-  __Runbooks\AzureLogin.ps1__: Child runbook that logs into your subscription using the RunAs account.
-  __Runbooks\SendMail.ps1__: Child runbook. It sends email notifications using SendGrid.
-  __Runbooks\UpdateNSG.ps1__: Child runbook. It updates NSG's.
-  __Runbooks\UpdateUDR.ps1__: Child runbook. It updates UDR's.

##How To Install
1) Clone the repository to your local machine.

2) Create a SendGrid account if you do not have one already. Create an API key and save it (you will need it in step 3).

3) Launch Powershell as Administrator (this is required to create the RunAs account).

4) Launch .\CreateAutomationAccount.ps1 and provide a value for the mandatory parameters:

- __resGroupName__: Name of the resource group to which you want to deploy the Automation Account
- __resGroupLocation__: Location of the resource group
- __subscriptionId__: your subscriptionId
- __password__: strong password that will be used to secure access to the self signed certificate used by the RunAs account
- __automationAccountName__: Name of the Automation Account that will be created
- __sendGridApiKey__: API Key for your SendGrid Account

5) Log into the Azure portal, browse to your newly created Azure account, update the Azure Modules and install the module AzureRM.Network. To do so, 

- browse to "Modules" and then click "Update Azure Modules";
- In the same pane, click "Browse Gallery", search AzureRM.Network, and import it.

6) In your Azure Automation Account, open the "Variables" pane and update them according to your monitoring needs:

- __monitoredFqdns__: Comma-separated list of FQDN that you want to monitor
- __monitoredRuleTag__: Name suffix for the rules (NSG rules and UDR's) that you want to be automatically updated in case of IP address changes
- __recipients__: Comma-separated list of email addresses you want notifications to be sent to
- __sender__: Email account you want email notifications to come from

7) Test the solution by running the runbook "MonitorFQDN". Please note that, in the first run, the script will learn and store the current IP address for each monitored FQDN, and will send out notifications for each FQDN, just like it IP address had changed.

8) Run ./CreateSchedules.ps1 to create schedules in your Automation Account, and link them to the "MonitorFQDN" runbook.

- __resGroupName__: Name of the resource group that will contain the Automation account
- __automationAccountName__: Name of the Automation account (shown in the portal)
- __subscriptionId__: Subscription Id
- __EnvironmentName__: Environemnt to log in to (allowed values: "AzureCloud",AzureUSGovernment)
- __pollingInterval__: How frequently (minutes) to perform DNS resolution for monitored FQDN's


