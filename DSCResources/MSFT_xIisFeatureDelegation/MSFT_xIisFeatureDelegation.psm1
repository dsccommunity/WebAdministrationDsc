# Suppressing this rule because Write-Verbose is called in Helper functions
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCUseVerboseMessageInDSCResource', '')]
param ()

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        NoWebAdministrationModule = Please ensure that WebAdministration module is installed.
        UnableToGetConfig         = Unable to get configuration data for '{0}'.
        ChangedMessage            = Changed overrideMode for '{0}' to '{1}'.
        VerboseGetTargetResource  = Get-TargetResource has been run.
'@
}

<#
        .SYNOPSIS
        This will return a hashtable of results 
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    [String] $oMode = Get-OverrideMode -Section $SectionName

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    return @{
        SectionName  = $SectionName
        OverrideMode = $oMode
    }
}

<#
        .SYNOPSIS
        This will set the desired state
#>
function Set-TargetResource
{
    <#
      .SYNOPSIS
        This will set the desired state
    #>
    
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
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
     
     Set-WebConfiguration -Location '' `
                          -Filter "/system.webServer/$SectionName" `
                          -PSPath 'machine/webroot/apphost' `
                          -Metadata 'overrideMode' `
                          -Value $OverrideMode
}

<#
        .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
#>
function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    [CmdletBinding()]
    [OutputType([System.Boolean])]
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

    [String] $oMode = Get-OverrideMode -Section $SectionName

    if ($oMode -eq $OverrideMode)
    {
        return $true
    }

    return $false
}

#region Helper functions

<#
    .SYNOPSIS
        Checks for a single value.
    .NOTES
        If $oMode is anything but Allow or Deny, we have a problem with our 
        Get-WebConfiguration call or the ApplicationHost.config file is corrupted.
#>
function Get-OverrideMode
{
    
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [String] $Section
    )

    Assert-Module

    Write-Verbose -Message 'Getting override mode'
    
    $webConfig = Get-WebConfiguration -Location '' `
                                      -Filter /system.webServer/$Section `
                                      -Metadata

    $oMode = $webConfig.Metadata.effectiveOverrideMode

    if ($oMode -notmatch "^(Allow|Deny)$")
    {
        $errorMessage = $($LocalizedData.UnableToGetConfig) -f $Section
        New-TerminatingError -ErrorId UnableToGetConfig `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory:InvalidResult
    }

    return $oMode
}


#endregion

Export-ModuleMember -function *-TargetResource
