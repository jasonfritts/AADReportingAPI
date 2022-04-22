$tId = "12345678-5ead-468c-a6ae-048e103d57f0"  # Add tenant ID from Azure Active Directory page on portal.
$agoDays = 7  # Will filter the log for $agoDays from the current date and time. 
$startDate = (Get-Date).AddDays(-($agoDays)).ToString('yyyy-MM-dd')  # Get filter start date.
$pathForExport = "./"  # The path to the local filesystem for export of the CSV file.

Connect-MgGraph -Scopes "AuditLog.Read.All" -TenantId $tId  # Or use Directory.Read.All.
Select-MgProfile "beta"  #

# Define the filtering strings. Below is example of finding all the Legacy Auth signins 
$filter = "ActivityDateTime ge $startDate"

# Get the interactive and non-interactive sign-ins based on filtering clauses.
$auditLogs= Get-MgAuditLogDirectoryAudit -Filter ($filter) -All


$auditLogs| Export-Csv -Path ($pathForExport + "AuditLogs_$tId.csv") -NoTypeInformation

