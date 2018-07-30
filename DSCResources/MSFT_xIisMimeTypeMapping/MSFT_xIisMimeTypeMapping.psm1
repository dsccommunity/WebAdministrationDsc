# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        NoWebAdministrationModule = Please ensure that WebAdministration module is installed.
        AddingType                = Adding MIMEType '{0}' for extension '{1}'
        RemovingType              = Removing MIMEType '{0}' for extension '{1}'
        TypeExists                = MIMEType '{0}' for extension '{1}' already exist
        TypeNotPresent            = MIMEType '{0}' for extension '{1}' is not present as requested
        VerboseGetTargetPresent   = MIMEType is present
        VerboseGetTargetAbsent    = MIMEType is absent
'@
}

Set-Variable ConstDefaultConfigurationPath -Option Constant -Value 'MACHINE/WEBROOT/APPHOST'
Set-Variable ConstSectionNode              -Option Constant -Value 'system.webServer/staticContent'

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER ConfigurationPath
        This can be either an IIS configuration path in the format computername/webroot/apphost, or the IIS module path in this format IIS:\\sites\\Default Web Site.

    .PARAMETER Extension
        The file extension to map such as .html or .xml.

    .PARAMETER MimeType
        The MIME type to map that extension to such as text/html.

    .PARAMETER Ensure
        Ensures that the MIME type mapping is Present or Absent.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $ConfigurationPath,

        [Parameter(Mandatory = $true)]
        [String]
        $Extension,

        [Parameter(Mandatory = $true)]
        [String]
        $MimeType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure
    )

    # Check if WebAdministration module is present for IIS cmdlets
    Assert-Module

    if (!$ConfigurationPath)
    {
        $ConfigurationPath = $ConstDefaultConfigurationPath
    }

    $currentMimeTypeMapping = Get-Mapping -ConfigurationPath $ConfigurationPath -Extension $Extension -Type $MimeType

    if ($null -eq $currentMimeTypeMapping)
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetAbsent
        return @{
            Ensure            = 'Absent'
            ConfigurationPath = $ConfigurationPath
            Extension         = $Extension
            MimeType          = $MimeType
        }
    }
    else
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetPresent
        return @{
            Ensure            = 'Present'
            ConfigurationPath = $ConfigurationPath
            Extension         = $currentMimeTypeMapping.fileExtension
            MimeType          = $currentMimeTypeMapping.mimeType
        }
    }
}

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER ConfigurationPath
        This can be either an IIS configuration path in the format computername/webroot/apphost, or the IIS module path in this format IIS:\\sites\\Default Web Site.

    .PARAMETER Extension
        The file extension to map such as .html or .xml.

    .PARAMETER MimeType
        The MIME type to map that extension to such as text/html.

    .PARAMETER Ensure
        Ensures that the MIME type mapping is Present or Absent.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $ConfigurationPath,

        [Parameter(Mandatory = $true)]
        [String]
        $Extension,

        [Parameter(Mandatory = $true)]
        [String]
        $MimeType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure
    )

    Assert-Module

    if (!$ConfigurationPath)
    {
        $ConfigurationPath = $ConstDefaultConfigurationPath
    }

    if ($Ensure -eq 'Present')
    {
        # add the MimeType
        Add-WebConfigurationProperty -PSPath $ConfigurationPath `
                                     -Filter $ConstSectionNode `
                                     -Name '.' `
                                     -Value @{fileExtension="$Extension";mimeType="$MimeType"}
        Write-Verbose -Message ($LocalizedData.AddingType -f $MimeType,$Extension)
    }
    else
    {
        # remove the MimeType
        Remove-WebConfigurationProperty -PSPath $ConfigurationPath `
                                        -Filter $ConstSectionNode `
                                        -Name '.' `
                                        -AtElement @{fileExtension="$Extension"}
        Write-Verbose -Message ($LocalizedData.RemovingType -f $MimeType,$Extension)
    }
}

<#
    .SYNOPSIS
        This will return a hashtable of results.

    .PARAMETER ConfigurationPath
        This can be either an IIS configuration path in the format computername/webroot/apphost, or the IIS module path in this format IIS:\\sites\\Default Web Site.

    .PARAMETER Extension
        The file extension to map such as .html or .xml.

    .PARAMETER MimeType
        The MIME type to map that extension to such as text/html.

    .PARAMETER Ensure
        Ensures that the MIME type mapping is Present or Absent.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $ConfigurationPath,

        [Parameter(Mandatory = $true)]
        [String]
        $Extension,

        [Parameter(Mandatory = $true)]
        [String]
        $MimeType,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure
    )

    Assert-Module

    if (!$ConfigurationPath)
    {
        $ConfigurationPath = $ConstDefaultConfigurationPath
    }

    $desiredConfigurationMatch = $true;

    $currentMimeTypeMapping = Get-Mapping -ConfigurationPath $ConfigurationPath -Extension $Extension -Type $MimeType

    if ($null -ne $currentMimeTypeMapping -and $Ensure -eq 'Present')
    {
        Write-Verbose -Message ($LocalizedData.TypeExists -f $MimeType,$Extension)
    }
    elseif ($null -eq $currentMimeTypeMapping -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.TypeNotPresent -f $MimeType,$Extension)
    }
    else
    {
        $desiredConfigurationMatch = $false
    }

    return $desiredConfigurationMatch
}

#region Helper Functions

<#
    .PARAMETER ConfigurationPath
        This can be either an IIS configuration path in the format computername/webroot/apphost, or the IIS module path in this format IIS:\\sites\\Default Web Site.

    .PARAMETER Extension
        The file extension to map such as .html or .xml.

    .PARAMETER Type
        The MIME type to map that extension to such as text/html.
#>
function Get-Mapping
{
    [CmdletBinding()]
    [OutputType([PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]
        $ConfigurationPath,

        [Parameter(Mandatory = $true)]
        [String]
        $Extension,

        [Parameter(Mandatory = $true)]
        [String]
        $Type
    )

    $filter = "$ConstSectionNode/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f $Extension, $Type

    return Get-WebConfiguration -PSPath $ConfigurationPath -Filter $filter
}

#endregion

Export-ModuleMember -Function *-TargetResource
