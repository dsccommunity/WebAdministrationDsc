# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

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
        TypeStatusUnknown         = MIMEType '{0}' for extension '{1}' is is an unknown status
        VerboseGetTargetPresent   = MIMEType is present
        VerboseGetTargetAbsent    = MIMEType is absent
'@
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    param
    (        
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MimeType,

        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [String]$Ensure
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    Assert-Module

    $mt = Get-Mapping -extension $Extension -type $MimeType 

    if ($null -eq $mt)
    {
        Write-Verbose -Message $LocalizedData.VerboseGetTargetAbsent
        return @{
            Ensure    = 'Absent'
            Extension = $null
            MimeType  = $null
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
    param
    (    
        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [String]$Ensure = 'Present',
            
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MimeType
    )

        Assert-Module

        [string]$psPathRoot = 'MACHINE/WEBROOT/APPHOST'
        [string]$sectionNode = 'system.webServer/staticContent'

        $mt = Get-Mapping -extension $Extension -type $MimeType 

        if ($null -eq $mt -and $Ensure -eq 'Present')
        {
            # add the MimeType            
            Add-WebConfigurationProperty -pspath $psPathRoot `
                                        -filter $sectionNode `
                                        -name '.' `
                                        -value @{fileExtension="$Extension";mimeType="$MimeType"}
            Write-Verbose -Message ($LocalizedData.AddingType -f $MimeType,$Extension);
        }
        elseif ($null -ne $mt -and $Ensure -eq 'Absent')
        {
            # remove the MimeType                      
            Remove-WebConfigurationProperty -pspath $psPathRoot `
                                            -filter $sectionNode `
                                            -name '.' `
                                            -AtElement @{fileExtension="$Extension"}
            Write-Verbose -Message ($LocalizedData.RemovingType -f $MimeType,$Extension);
        }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (    
        [Parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [String]$Ensure = 'Present',
    
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MimeType
    )

    [bool]$DesiredConfigurationMatch = $true;
    
    Assert-Module

    $mt = Get-Mapping -extension $Extension -type $MimeType 

    if (($null -eq $mt -and $Ensure -eq 'Present') -or ($null -ne $mt -and $Ensure -eq 'Absent'))
    {
        $DesiredConfigurationMatch = $false;
    }
    elseif ($null -ne $mt -and $Ensure -eq 'Present')
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
        $DesiredConfigurationMatch = $false;
        Write-Verbose -Message ($LocalizedData.TypeStatusUnknown -f $MimeType,$Extension);
    }
    
    return $DesiredConfigurationMatch
}

#region Helper Functions

Function Get-Mapping
{
   
    [CmdletBinding()]
    param
    (
        [String]$extension,
        
        [String]$type
    )

    [String]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + `
                       $extension + "' and @mimeType='" + $type + "']"
    return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .
}

#endregion

Export-ModuleMember -function *-TargetResource
