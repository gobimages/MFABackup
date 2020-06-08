# Input bindings are passed in via param block.
param($Timer)
Connect-azaccount -Identity
# Get the current universal time in the default string format
$currentUTCtime = (Get-Date).ToUniversalTime()

# The 'IsPastDue' porperty is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}

# Write an information log with the current time.
$clientId = "66f6ff19-8bdc-4961-a9e6-d9c91d456775"
$tenantId = "81b2b335-4298-4b51-837e-e71a9da239b0"
$clientSecret = 'ZwZ.1Jyi50g.qcxKsL4.3172~8TxNi_4i2'
$CName = "capolicy$(get-date -Format dd-MM-yyyy)"
# Construct URI
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

# Construct Body
$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
    
}

# Get OAuth 2.0 Token
$tokenRequest = Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing

# Access Token
$token = $tokenRequest.access_token
$Headers = @{"Authorization" = "Bearer $token" }

$AUri = "https://graph.microsoft.com/beta/identity/conditionalAccess/policies"
$apiCall = Invoke-RestMethod -Method GET -Uri $AUri -ContentType "application/json" -Headers $Headers -ErrorAction Stop
$key = (Get-AzStorageAccountKey -ResourceGroupName branch -Name branchdiag)[0].value
$StorageContext = New-AzStorageContext -StorageAccountName branchdiag -StorageAccountKey $key
$Err = $null
$Err = Get-AzStorageContainer -Name $CName -Context $StorageContext -ErrorAction Ignore
if ($Err.Name -eq $null){
$Container = New-AzStorageContainer -Name $CName -Context $StorageContext -Permission Off
$Filename = "D:\home\tmp\CA_$(get-date -Format dd-MM-yyyy)"
New-Item -Path $Filename -ItemType Directory
for ($i = 0; $i -lt ($apiCall.value).count; $i++){
$apiCall.value[$i] | ConvertTo-Json -Depth 4 | Out-File $Filename\"$($apiCall.value[$i].displayName).json"
}
Get-ChildItem -File $Filename| Set-AzStorageBlobContent -Container $Container.Name -Context $StorageContext
Remove-Item -Path $Filename -Recurse
}
Else{Write-output "Backup already Taken" Break}



