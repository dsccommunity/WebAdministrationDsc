######################################################################################
# DSC Resource for IIS Server level MIME Type mappings
######################################################################################
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
AddingType=Adding MIMEType '{0}' for extension '{1}'
RemovingType=Removing MIMEType '{0}' for extension '{1}'
TypeExists=MIMEType '{0}' for extension '{1}' already exist
TypeNotPresent=MIMEType '{0}' for extension '{1}' is not present as requested
TypeStatusUnknown=MIMEType '{0}' for extension '{1}' is is an unknown status
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
# This function will get the Mime type for a file extension
######################################################################################
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
        [string]$Ensure
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    $mt = GetMapping -extension $Extension -type $MimeType 

    if ($mt -eq $null)
    {
        return @{
            Ensure = 'Absent'
            Extension = $null
            MimeType = $null
        }
    }
    else
    {
        return @{
            Ensure = 'Present'
            Extension = $mt.fileExtension
            MimeType = $mt.mimeType
        }
    }
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will add or remove a MIME type mapping
######################################################################################
function Set-TargetResource
{
    param
    (    
        [ValidateSet('Present', 'Absent')]
        [Parameter(Mandatory)]
        [string]$Ensure = 'Present',
            
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MimeType
    )

        CheckIISPoshModule

        [string]$psPathRoot = 'MACHINE/WEBROOT/APPHOST'
        [string]$sectionNode = 'system.webServer/staticContent'

        $mt = GetMapping -extension $Extension -type $MimeType 

        if ($mt -eq $null -and $Ensure -eq 'Present')
        {
            # add the MimeType            
            Add-WebConfigurationProperty -pspath $psPathRoot  -filter $sectionNode -name '.' -value @{fileExtension="$Extension";mimeType="$MimeType"}
            Write-Verbose($LocalizedData.AddingType -f $MimeType,$Extension);
        }
        elseif ($mt -ne $null -and $Ensure -eq 'Absent')
        {
            # remove the MimeType                      
            Remove-WebConfigurationProperty -pspath $psPathRoot -filter $sectionNode -name '.' -AtElement @{fileExtension="$Extension"}
            Write-Verbose($LocalizedData.RemovingType -f $MimeType,$Extension);
        }
}

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given MIME type mapping has the desired state, Present or Absent
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (    
        [Parameter(Mandatory)]
        [ValidateSet('Present', 'Absent')]
        [string]$Ensure = 'Present',
    
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Extension,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MimeType
    )

    [bool]$DesiredConfigurationMatch = $true;
    
    CheckIISPoshModule

    $mt = GetMapping -extension $Extension -type $MimeType 

    if (($mt -eq $null -and $Ensure -eq 'Present') -or ($mt -ne $null -and $Ensure -eq 'Absent'))
    {
        $DesiredConfigurationMatch = $false;
    }
    elseif ($mt -ne $null -and $Ensure -eq 'Present')
    {
        # Already there 
        Write-Verbose($LocalizedData.TypeExists -f $MimeType,$Extension);
    }
    elseif ($mt -eq $null -and $Ensure -eq 'Absent')
    {
        # TypeNotPresent
        Write-Verbose($LocalizedData.TypeNotPresent -f $MimeType,$Extension);
    }
    else
    {
        $DesiredConfigurationMatch = $false;
        Write-Verbose($LocalizedData.TypeStatusUnknown -f $MimeType,$Extension);
    }
    
    return $DesiredConfigurationMatch
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

Function GetMapping([string]$extension,[string]$type)
{
    [string]$filter = "system.webServer/staticContent/mimeMap[@fileExtension='" + $extension + "' and @mimeType='" + $type + "']"
    return Get-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -filter $filter -Name .
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
