# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ErrorWebsiteNotRunning = The website '{0}' is not correctly running.
        VerboseUrlReturnStatusCode = Url {0} returned status code {1}.
        VerboseTestTargetFalseStatusCode = Status code of url {0} does not match the desired state.
        VerboseTestTargetFalseExpectedContent = Content of url {0} does not match the desired state.
'@
}

<#
    .SYNOPSYS
        This will return a hashtable of results.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $RelativeUrl,

        [UInt16[]]
        $ValidStatusCodes = [int][Net.HttpStatusCode]::OK,

        [String]
        $ExpectedContent
    )

    if (Test-WebSiteRunning $WebSiteName $RelativeUrl $ValidStatusCodes $ExpectedContent)
    {
        return @{
            Ensure           = 'Present'
            WebSiteName      = $WebSiteName
            RelativeUrl      = $RelativeUrl
            ValidStatusCodes = [object[]]$ValidStatusCodes
            ExpectedContent  = $ExpectedContent
        }
    }
    else
    {
        $errorMessage = $LocalizedData.ErrorWebsiteNotRunning -f $WebSiteName
        New-TerminatingError -ErrorId 'WebsiteNotRunning' `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory 'InvalidResult'
    }
}

<#
    .SYNOPSYS
        This will set the desired state.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $RelativeUrl,

        [UInt16[]]
        $ValidStatusCodes = [int][Net.HttpStatusCode]::OK,

        [String]
        $ExpectedContent
    )

    $errorMessage = $LocalizedData.ErrorWebsiteNotRunning -f $WebSiteName
    New-TerminatingError -ErrorId 'WebsiteNotRunning' `
                         -ErrorMessage $errorMessage `
                         -ErrorCategory 'InvalidResult'
}

<#
    .SYNOPSYS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $RelativeUrl,

        [UInt16[]]
        $ValidStatusCodes = [int][Net.HttpStatusCode]::OK,

        [String]
        $ExpectedContent
    )

    return Test-WebSiteRunning $WebSiteName $RelativeUrl $ValidStatusCodes $ExpectedContent
}

#region Helper Functions

function Test-WebSiteRunning
{
    [OutputType([Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $RelativeUrl,

        [UInt16[]]
        $ValidStatusCodes,

        [String]
        $ExpectedContent
    )

    function Get-UrlStatus
    {
        [OutputType([Hashtable])]
        param ([string] $Url)

        try
        {
            $webResponse = Invoke-WebRequest -Uri $Url -UseBasicParsing -DisableKeepAlive

            return @{
                StatusCode = $webResponse.StatusCode
                Content = $webResponse.Content -replace "`r`n", "`n"
            }
        }
        catch [Net.WebException]
        {
            return @{
                StatusCode = [int]$_.Exception.Response.StatusCode
                Content = ''
            }
        }
    }

    $bindings = Get-WebBinding -Name $WebSiteName

    foreach ($binding in $bindings)
    {
        if ($binding.Protocol -in @('http', 'https'))
        {
            # Extract IPv6 address
            if ($binding.bindingInformation -match '^\[(.*?)\]\:(.*?)\:(.*?)$') 
            {
                $ipAddress = $Matches[1]
                $port      = $Matches[2]
                $hostName  = $Matches[3]
            }
            else
            {
                $ipAddress, $port, $hostName = $binding.bindingInformation -split '\:'
            }

            if (-not $hostName)
            {
                $hostName = 'localhost'
            }

            $url = "$($binding.protocol)://$($hostName):$port$RelativeUrl"

            $urlStatus = Get-UrlStatus $url

            Write-Verbose -Message ($LocalizedData.VerboseUrlReturnStatusCode -f $url, $urlStatus.StatusCode)
            
            if ($ValidStatusCodes -notcontains $urlStatus.StatusCode)
            {
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseStatusCode -f $url)
                
                return $false
            }

            if ($ExpectedContent -and $urlStatus.Content -ne $ExpectedContent)
            {
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseExpectedContent -f $url)

                return $false
            }
        }
    }

    return $true
}

#endregion

Export-ModuleMember -Function *-TargetResource
