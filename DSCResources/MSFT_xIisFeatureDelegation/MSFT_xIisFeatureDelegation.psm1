######################################################################################
# DSC Resource for IIS Server level Feature Delegation
######################################################################################

Import-Module $PSScriptRoot\..\Helper.psm1 -Verbose:$false

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        NoWebAdministrationModule   =   Please ensure that WebAdministration module is installed.
        UnableToGetConfig           =   Unable to get configuration data for '{0}'
        ChangedMessage              =   Changed overrideMode for '{0}' to {1}
'@
}

<#
    The Get-TargetResource cmdlet.
    This function will get the Mime type for a file extension
#>
function Get-TargetResource
{
  [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $SectionName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String] $OverrideMode
    )

    [string] $oMode = Get-OverrideMode -section $SectionName

    if ($oMode -eq $OverrideMode)
    {
        $ensureResult = 'Present'
    }
    else
    {
        $ensureResult = 'Absent'
    }

    return @{
        SectionName = $SectionName
        OverrideMode = $oMode
        Ensure = $ensureResult
    }
}

<#
    The Set-TargetResource cmdlet.
    This function set the OverrideMode for a given section if not already correct
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $SectionName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String] $OverrideMode
    )

     Write-Verbose($($LocalizedData.ChangedMessage) -f $SectionName, $OverrideMode)
     Set-WebConfiguration -Location '' -Filter "/system.webServer/$SectionName" -PSPath 'machine/webroot/apphost' -Metadata overrideMode -Value $OverrideMode
}

<#
    The Test-TargetResource cmdlet.
    This will test if the given section has the required OverrideMode
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$SectionName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String]$OverrideMode
    )

    [string] $oMode = Get-OverrideMode -Section $SectionName

    if ($oMode -eq $OverrideMode)
    {
        # in this case we have our desired state
        return $true
    }

    # state doesn't match or doesn't exist
    return $false
}

Function Get-OverrideMode
{
    param
    (
        [string] $Section
    )

    # Check that the WebAdministration Module is available.
    Assert-Module

    [string] $oMode = ((Get-WebConfiguration -Location '' -Filter /system.webServer/$Section -Metadata).Metadata).effectiveOverrideMode

    <#
        Check for a single value.
        If $oMode is anything but Allow or Deny, we have a problem with our Get-WebConfiguration call
        or the ApplicationHost.config file is corrupted.
    #>
    if ($oMode -notmatch "^(Allow|Deny)$")
    {
        $errorMessage = $($LocalizedData.UnableToGetConfig) -f $Section
        New-TerminatingError -ErrorId UnableToGetConfig -ErrorMessage $errorMessage -ErrorCategory:InvalidResult
    }

    return $oMode
}

#  FUNCTIONS TO BE EXPORTED
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
