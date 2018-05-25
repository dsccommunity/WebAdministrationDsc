# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        GetOverrideMode           = Getting override mode for '{0}'.
        NoWebAdministrationModule = Please ensure that WebAdministration module is installed.
        UnableToGetConfig         = Unable to get configuration data for '{0}'.
        VerboseGetTargetResource  = Get-TargetResource has been run.
        VerboseSetTargetResource  = Changed overrideMode for '{0}' to '{1}'.
'@
}

<#
    .SYNOPSIS
        This will return a hashtable of results

    .PARAMETER Filter
        Specifies the IIS configuration section to lock or unlock.

    .PARAMETER Path
        Specifies the configuration path. This can be either an IIS configuration path in the format
        computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site.

    .PARAMETER OverrideMode
        Determines whether to lock or unlock the specified section.
#>
function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String]
        $OverrideMode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path
    )

    [String] $currentOverrideMode = Get-OverrideMode -Filter $Filter -Path $Path

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    return @{
        Path         = $Path
        Filter       = $Filter
        OverrideMode = $OverrideMode
    }
}

<#
    .SYNOPSIS
        This will set the resource to the desired state.

    .PARAMETER Filter
        Specifies the IIS configuration section to lock or unlock.

    .PARAMETER Path
        Specifies the configuration path. This can be either an IIS configuration path in the format
        computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site.

    .PARAMETER OverrideMode
        Determines whether to lock or unlock the specified section.
#>
function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String]
        $OverrideMode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path
    )

     Write-Verbose -Message ( $($LocalizedData.VerboseSetTargetResource) -f $Filter, $OverrideMode )

     Set-WebConfiguration -Filter $Filter -PsPath $PsPath -Metadata 'overrideMode' -Value $OverrideMode
}

<#
    .SYNOPSIS
        This will return whether the resource is in desired state.

    .PARAMETER Filter
        Specifies the IIS configuration section to lock or unlock.

    .PARAMETER OverrideMode
        Determines whether to lock or unlock the specified section.

    .PARAMETER Path
        Specifies the configuration path. This can be either an IIS configuration path in the format
        computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site.

#>
function Test-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String]
        $OverrideMode,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path
    )

    [String] $currentOverrideMode = Get-OverrideMode -Filter $Filter -Path $Path

    if ($currentOverrideMode -eq $OverrideMode)
    {
        return $true
    }

    return $false
}

#region Helper functions
<#
    .SYNOPSIS
        This will return the current override mode for the specified configsection.

    .PARAMETER Filter
        Specifies the IIS configuration section.

    .PARAMETER PsPath
        Specifies the configuration path. This can be either an IIS configuration path in the format
        computer machine/webroot/apphost, or the IIS module path in this format IIS:\sites\Default Web Site.

#>
function Get-OverrideMode
{
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Filter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path
    )

    Assert-Module

    Write-Verbose -Message ( $($LocalizedData.ChangedMessage) -f $Filter )

    $webConfig = Get-WebConfiguration -PsPath $Path -Filter $Filter -Metadata

    $currentOverrideMode = $webConfig.Metadata.effectiveOverrideMode

    if ($currentOverrideMode -notmatch "^(Allow|Deny)$")
    {
        $errorMessage = $($LocalizedData.UnableToGetConfig) -f $Filter
        New-TerminatingError -ErrorId UnableToGetConfig `
                             -ErrorMessage $errorMessage `
                             -ErrorCategory:InvalidResult
    }

    return $currentOverrideMode
}


#endregion

Export-ModuleMember -function *-TargetResource
