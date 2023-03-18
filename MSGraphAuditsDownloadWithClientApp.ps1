# ------------------------------------------------------------
# Copyright (c) Microsoft Corporation.  All rights reserved.
# ------------------------------------------------------------

Import-Module Azure

# Replace with your tenantId or tenantDomain
$tenantId = ""

# Replace with your desired time ranges
$toDate = "{0:s}" -f (get-date).ToUniversalTime() + "Z"
$fromDate = "{0:s}" -f (get-date).AddDays(-7).ToUniversalTime() + "Z"

# You can add more filters here
$url = "https://graph.microsoft.com/beta/auditLogs/directoryAudits?`$filter=activityDateTime ge $fromDate and activityDateTime le $toDate"

# By default, it saves the result to DownloadedReport_currentTime.csv. Change it to different file name as needed.
$now = "{0:yyyyMMdd_hhmmss}" -f (get-date)
$outputFile = ".\AAD_AuditReport_$now.csv"

# Configure a client App with the following permissions:
# -----------------------------------------------------------------------------------------------------------------
# AppId                                                           | Application Permissions | Delegated Permissions
# Windows Azure Active Directory (Microsoft.Azure.ActiveDirectory)| Read Directory Data     |
# Microsoft Graph                                                 | Read all audit log data |
# ------------------------------------------------------------------------------------------------------------------
$clientId       = ""     # ApplicationId, check the documentation for the permissions
$clientSecret   = ""     # Should be a ~44 character string insert your info here


###################################
#### DO NOT MODIFY BELOW LINES ####
###################################
Function ConvertTo-FlatObject {
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeLine)][Object[]]$Objects,
        [String]$Separator = ".",
        [ValidateSet("", 0, 1)]$Base = 1,
        [int]$Depth = 5,
        [Parameter(DontShow)][String[]]$Path,
        [Parameter(DontShow)][System.Collections.IDictionary] $OutputObject
    )
    Begin {
        $InputObjects = [System.Collections.Generic.List[Object]]::new()
    }
    Process {
        foreach ($O in $Objects) {
            $InputObjects.Add($O)
        }
    }
    End {
        If ($PSBoundParameters.ContainsKey("OutputObject")) {
            $Object = $InputObjects[0]
            $Iterate = [ordered] @{}
            if ($null -eq $Object) {
                #Write-Verbose -Message "ConvertTo-FlatObject - Object is null"
            } elseif ($Object.GetType().Name -in 'String', 'DateTime', 'TimeSpan', 'Version', 'Enum') {
                $Object = $Object.ToString()
            } elseif ($Depth) {
                $Depth--
                If ($Object -is [System.Collections.IDictionary]) {
                    $Iterate = $Object
                } elseif ($Object -is [Array] -or $Object -is [System.Collections.IEnumerable]) {
                    $i = $Base
                    foreach ($Item in $Object.GetEnumerator()) {
                        $Iterate["$i"] = $Item
                        $i += 1
                    }
                } else {
                    foreach ($Prop in $Object.PSObject.Properties) {
                        if ($Prop.IsGettable) {
                            $Iterate["$($Prop.Name)"] = $Object.$($Prop.Name)
                        }
                    }
                }
            }
            If ($Iterate.Keys.Count) {
                foreach ($Key in $Iterate.Keys) {
                    ConvertTo-FlatObject -Objects @(, $Iterate["$Key"]) -Separator $Separator -Base $Base -Depth $Depth -Path ($Path + $Key) -OutputObject $OutputObject
                }
            } else {
                $Property = $Path -Join $Separator
                $OutputObject[$Property] = $Object
            }
        } elseif ($InputObjects.Count -gt 0) {
            foreach ($ItemObject in $InputObjects) {
                $OutputObject = [ordered]@{}
                ConvertTo-FlatObject -Objects @(, $ItemObject) -Separator $Separator -Base $Base -Depth $Depth -Path $Path -OutputObject $OutputObject
                [PSCustomObject] $OutputObject
            }
        }
    }
}

Function Get-AppToken($tenantId, $clientId, $clientSecret)
{
	$loginURL       = "https://login.windows.net"
	$msgraphEndpoint = "https://graph.microsoft.com"

	# Get an Oauth 2 access token based on client id, secret and tenant domain
	$body       = @{grant_type="client_credentials";resource=$msgraphEndpoint;client_id=$clientId;client_secret=$clientSecret}
    $url =   "$loginURL/$tenantId/oauth2/token?api-version=1.0"
	$oauth      = Invoke-RestMethod -Method Post -Uri $url -Body $body
	$token = $oauth.access_token

if ($token -eq $null) {
    $ErrorString = "ERROR: Failed to get an Access Token"
    Write-Output $ErrorString
    $Error = New-Object System.Exception $ErrorString
    Throw $Error
}
return @{'Authorization'="$($oauth.token_type) $($token)"}
}


Write-Output "--------------------------------------------------------------"
Write-Output "Downloading report from $url"
Write-Output "Output file: $outputFile"
Write-Output "--------------------------------------------------------------"

# Call Microsoft Graph
$count=0
$retryCount = 0
$oneSuccessfulFetch = $False

$headers = Get-AppToken -clientSecret $clientSecret -clientId $clientId -tenantId $tenantId

Do {
    Write-Output "Fetching data using Url: $url"

    Try {
        $myReport = (Invoke-WebRequest -UseBasicParsing -Headers $headers -Uri $url)
        $convertedReport = ($myReport.Content | ConvertFrom-Json).value
	$convertedReport | ConvertTo-FlatObject | ConvertTo-Csv -NoTypeInformation | Add-Content $outputFile
        $url = ($myReport.Content | ConvertFrom-Json).'@odata.nextLink'
        $count = $count+$convertedReport.Count
        Write-Output "Total Fetched: $count"
        $oneSuccessfulFetch = $True
        $retryCount = 0        
    }
    Catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Output $statusCode
        Write-Output $_.Exception.Message
        if($statusCode -eq 401 -and $oneSuccessfulFetch)
        {
            # Token might have expired! Renew token and try again
            $headers = Get-AppToken -clientSecret $clientSecret -clientId $clientId -tenantId $tenantId
            $oneSuccessfulFetch = $False
        }
        elseif($statusCode -eq 429)
        {
            # throttled request, wait for a few seconds and retry
            Start-Sleep -s 5
        }
        elseif($statusCode -eq 403 -or $statusCode -eq 400 -or $statusCode -eq 401)
        {
            Write-Output "Please check the permissions of the user"
            break;
        }
        else {
            if ($retryCount -lt 5) {
                Write-Output "Retrying..."
                $retryCount++
            }
            else {
                Write-Output "Download request failed. Please try again in the future."
                break
            }
        }
     }
    Catch {
        $exType = $_.Exception.GetType().FullName
        $exMsg = $_.Exception.Message

        Write-Output "Exception: $_.Exception"
        Write-Output "Error Message: $exType"
        Write-Output "Error Message: $exMsg"

         if ($retryCount -lt 5) {
            Write-Output "Retrying..."
            $retryCount++
        }
        else {
            Write-Output "Download request failed. Please try again in the future."
            break
        }
    }

    Write-Output "--------------------------------------------------------------"
} while(-not[string]::IsNullOrEmpty($url))
