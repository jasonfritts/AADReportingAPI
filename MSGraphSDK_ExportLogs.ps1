# NOTE: First install MSGraph PowerShell module See: https://docs.microsoft.com/en-us/graph/powershell/installation﻿

$tId = "12345678-5ead-468c-a6ae-048e103d57f0"  # Add tenant ID from Azure Active Directory overview page on portal.azure.com
$agoDays = 7  # Will filter the log for $agoDays from the current date and time. 
$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd')  # Get filter start date.
$pathForExport = "./"  # The path to the local filesystem for export of the CSV file.

Connect-MgGraph -Scopes "AuditLog.Read.All" -TenantId $tId  # Or use Directory.Read.All.
Select-MgProfile "beta"  #

# Define the filtering strings. Below is a example filter of finding all the Legacy Auth signins
# For help on filters see https://docs.microsoft.com/en-us/graph/query-parameters#filter-parameter
# To download ALL logs, do not define a filter and remove the -Filter flag from line 16 below.
$filter = "createdDateTime ge $startDate and (clientAppUsed eq 'AutoDiscover' or clientAppUsed eq 'Exchange ActiveSync' or clientAppUsed eq 'Exchange Online PowerShell' or clientAppUsed eq 'Exchange Web Services' or clientAppUsed eq 'IMAP4' or clientAppUsed eq 'MAPI Over HTTP' or clientAppUsed eq 'Offline Address Book' or clientAppUsed eq 'Other clients' or clientAppUsed eq 'Outlook Anywhere (RPC over HTTP)' or clientAppUsed eq 'POP3' or clientAppUsed eq 'Reporting Web Services' or clientAppUsed eq 'Authenticated SMTP' or clientAppUsed eq 'Outlook Service')"

# Get the interactive and non-interactive sign-ins based on filtering clauses.
$signIns = Get-MgAuditLogSignIn -Filter ($filter) -All


$columnList = @{  # Enumerate the list of properties to be exported to the CSV files.
    Property = "CorrelationId", "createdDateTime", "userPrincipalName", "userId",
               "UserDisplayName", "AppDisplayName", "AppId", "IPAddress", "isInteractive",
               "ResourceDisplayName", "ResourceId", "UserAgent"
}

$signIns | Select-Object @columnList | Export-Csv -Path ($pathForExport + "LegacyAuthSignIns_$tId.csv") -NoTypeInformation



