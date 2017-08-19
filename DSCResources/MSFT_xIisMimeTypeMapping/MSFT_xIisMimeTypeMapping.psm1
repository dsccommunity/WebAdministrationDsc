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

function Get-TargetResource
{
    <#
        .SYNOPSIS
            This will return a hashtable of results 
    #>
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $MimeType,

        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [String] $Ensure
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    Assert-Module

    $mt = Get-Mapping -Extension $Extension -Type $MimeType 

    if ($null -eq $mt)
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetAbsent
        return @{
            Ensure    = 'Absent'
            Extension = $Extension
            MimeType  = $MimeType
        }
    }
    else
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetPresent
        return @{
            Ensure    = 'Present'
            Extension = $mt.fileExtension
            MimeType  = $mt.mimeType
        }
    }
}

function Set-TargetResource
{
    <#
        .SYNOPSIS
            This will set the desired state
    #>
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $MimeType,

        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [String] $Ensure
    )

    Assert-Module

    if ($Ensure -eq 'Present')
    {
        # add the MimeType            
        Add-WebConfigurationProperty -PSPath $ConstDefaultConfigurationPath `
                                     -Filter $ConstSectionNode `
                                     -Name '.' `
                                     -Value @{fileExtension="$Extension";mimeType="$MimeType"}
        Write-Verbose -Message ($LocalizedData.AddingType -f $MimeType,$Extension);
    }
    else
    {
        # remove the MimeType                      
        Remove-WebConfigurationProperty -PSPath $ConstDefaultConfigurationPath `
                                        -Filter $ConstSectionNode `
                                        -Name '.' `
                                        -AtElement @{fileExtension="$Extension"}
        Write-Verbose -Message ($LocalizedData.RemovingType -f $MimeType,$Extension);
    }
}

function Test-TargetResource
{
    <#
        .SYNOPSIS
            This tests the desired state. If the state is not correct it will return $false.
            If the state is correct it will return $true
    #>
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $MimeType,

        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [String] $Ensure
    )

    $desiredConfigurationMatch = $true;
    
    Assert-Module

    $mt = Get-Mapping -Extension $Extension -Type $MimeType 

    if ($null -ne $mt -and $Ensure -eq 'Present')
    {
        # Already there 
        Write-Verbose -Message ($LocalizedData.TypeExists -f $MimeType,$Extension);
    }
    elseif ($null -eq $mt -and $Ensure -eq 'Absent')
    {
        # TypeNotPresent
        Write-Verbose -Message ($LocalizedData.TypeNotPresent -f $MimeType,$Extension);
    }
    else
    {
        $desiredConfigurationMatch = $false;
    }
    
    return $desiredConfigurationMatch
}

#region Helper Functions

function Get-Mapping
{
    [CmdletBinding()]
    param
    (
        [String] $Extension,
        
        [String] $Type
    )

    $filter = "$ConstSectionNode/mimeMap[@fileExtension='{0}' and @mimeType='{1}']" -f $Extension, $Type

    return Get-WebConfiguration -PSPath $ConstDefaultConfigurationPath -Filter $filter
}

#endregion

Export-ModuleMember -Function *-TargetResource
