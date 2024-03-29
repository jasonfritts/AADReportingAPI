![#f03c15](https://via.placeholder.com/15/f03c15/000000?text=+) `UPDATE:`
A new script using the latest [Microsoft Graph SDK PowerShell module](https://docs.microsoft.com/en-us/powershell/microsoftgraph/overview?view=graph-powershell-beta) can also be used instead of below AADReportingAPI.  See examples at [MSGraphSDK_ExportLogs.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphSDK_ExportLogs.ps1) and [MSGraphSDK_ExportAuditLogs.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphSDK_ExportAuditLogs.ps1).  The MSGraph SDK PowerShell module has built in throttling retry handling as per [How is API throttling handled in the Powershell Graph functions](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/281) MSGraph SDK will perform a max of 3 retries when throttling is encountered and there is an [active feature request](https://github.com/microsoftgraph/msgraph-sdk-powershell/issues/1106) to allow the customization of MaxRetry.

# AADReportingAPI

These Powershell scripts can be used to download Azure AD Audit and Signin logs via the Graph API.  They have better error\throttling handling so can be used when you are trying to download a large amount of logs and the AAD portal or AAD Powershell module return throttling or limited logs.

  * [Prerequisites](#prerequisites)
  * [Download logs manually using user credentials](#download-logs-manually-using-user-credentials)
  * [Download logs using AAD application credentials](#download-logs-using-aad-application-credentials)

## Prerequisites
1. You must first install the [Azure PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/servicemanagement/install-azure-ps?view=azuresmps-4.0.0)
2. Verify it is installed by running cmd Import-Module Azure

For using AAD application credentials instead of user credentials, you must additionally
1. [Register an Azure AD Application](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
2. [Create a client secret for this Azure AD application](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-client-secret)
3. Grant this Azure AD application API permissions for the following APIs:

    Windows Azure Active Directory (Microsoft.Azure.ActiveDirectory) = Read Directory Data <br>
    Microsoft Graph                                                  = Read all audit log data

4. Update the PowerShell scripts to match your created Client ID and Client Secret and Tenant ID

## Download logs manually using user credentials

If you only need to download AAD audit or sign in logs one time and want to authenticate via user credentials, you can use either [MSGraphAuditsDownload.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphAuditsDownload.ps1) or [MSGraphSignInsDownload.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphSignInsDownload.ps1).

First download one of these scripts, and edit the line #8 to reference your tenantID  example $tenantID = "mytenant.onmicrosoft.com".

Next if you want to download more than 7 days worth of logs, edit line line 12 for the number of days you need to download.  Example : $fromDate = "{0:s}" -f (get-date).AddDays(-31).ToUniversalTime() + "Z"

Finally save and run this script, you should receive a login prompt and you will need to login with an Azure AD user who has permisisons to access logs.

## Download logs using AAD application credentials

If you need to configure this script to be run in automated fashion, you can use either [MSGraphAuditsDownloadWithClientApp.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphAuditsDownloadWithClientApp.ps1) or [MSGraphSignDownloadWithClientApp.ps1](https://github.com/jasonfritts/AADReportingAPI/blob/master/MSGraphSignDownloadWithClientApp.ps1) depending on the type of logs you need to download.

After downloading the scripts locally, you will need to edit line 8 to reference your tenantID  example $tenantID = "mytenant.onmicrosoft.com".

You will also need to edit line 27 and 28 to reference your clientID and clientSecret created in the [Prerequisites](#prerequisites) section of this Readme document.

Next if you want to download more than 7 days worth of logs, edit line line 12 for the number of days you need to download.  Example : $fromDate = "{0:s}" -f (get-date).AddDays(-31).ToUniversalTime() + "Z"

Finally save and run this script, and it will authenticate using the AAD client application credentials you provided for automated downloading of logs.
