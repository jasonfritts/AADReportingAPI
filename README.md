# AADReportingAPI

These Powershell scripts can be used to download Azure AD Audit and Signin logs via the Graph API.  They have better error\throttling handling so can be used when you are trying to download a large amount of logs.

## Prerequisites
1. You must first install the Azure PowerShell module via PowerShell cmdlet Install-Module Azure
2. Verify it is installed by running cmd Import-Module Azure

For using application credentials instead of user credentials, you must additionally
1. Register an Azure AD Application - https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app
2. Create a client secret for this Azure AD application - https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app#add-a-client-secret
3. Grant this Azure AD applicaiton API permissions for the following APIs:

    Windows Azure Active Directory (Microsoft.Azure.ActiveDirectory) = Read Directory Data <br>
    Microsoft Graph                                                  = Read all audit log data

4. Update the PowerShell scripts to match your created Client ID and Client Secret
