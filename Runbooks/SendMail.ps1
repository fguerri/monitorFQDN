#######################################################################################################
# SendMail.ps1: This runbook sends email messages when IP address changes are detected
#######################################################################################################

# Input parameters passed by calling runbook
param (
    # Previous IP address for FQDN currently being processed
    [Parameter(Mandatory=$true)][string]$oldIpAddress,
    # Previous IP address for FQDN currently being processed
    [Parameter(Mandatory=$true)][string]$newIpAddress
)

# Read values from automation variables
$sendGridApiUrl = Get-AutomationVariable -Name 'sendGridApiUrl'
$apiKey= Get-AutomationVariable -Name 'sendGridApiKey'
$recipients = Get-AutomationVariable -Name 'recipients'
$sender = Get-AutomationVariable -Name 'sender'

# Parse string variable containing list of recipients
$recipientsArray = $recipients.Split(",;").trim()

# Email message body
$messageBody = "The IP address for your monitored FQDN $fqdn has changed. Old Value: $oldIpAddress. New Value: $newIpAddress"

# We now build the JSON object to call SendGrid's API. See https://app.sendgrid.com/guide/integrate/langs/curl for more info 
 
# Build an array of hash tables representing the recipients. Each hashtable contains one entry with format email=<email address of recipient>
$jsonRecipientsArray = @()
foreach ($rep in $recipientsArray) {
    $jsonRecipientsArray = $jsonRecipientsArray + @{email = "$rep"}
}
        
# Sendgrid expects a JSON object with the follwoing properties: 
# 1) personalizations: in our case, the list of email recipients
# 2) from: email address of the sender, as it will be seen by recipients
# 3) subject: subject of the email message
# 4) content: content type and actual content of the email message
$requestBody = @{
    personalizations = @(@{to = $jsonRecipientsArray})
    from = @{email = $sender}
    subject = "Monitored IP Address has changed!"
    content = @(@{type = "text/plain"; value = $messageBody})
}   
    
# The variable $requestBody now contains a hashtable that mimicks the structure of the JSON object that SendGrid wants. Let's convert the hashtable to a JSON string
$requestBody = $requestBody | ConvertTo-Json -Depth 5

# SendGrid API requires the API key to be sent in Authorization header. See https://app.sendgrid.com/guide/integrate/langs/curl for more info
$headers = @{Authorization = "Bearer" + " " + $apiKey}
        
# Send request to SendGrid
$resp = wget -Uri $sendGridApiUrl -Headers $headers -Method Post -Body $requestBody -ContentType "application/json" -UseBasicParsing

write-output ("SendMail: Mail sent!")