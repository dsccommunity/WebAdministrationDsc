######################################################################################
# DSC Resource for IIS Server level Feature Delegation
######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
UnableToGetConfig=Unable to get configuration data for '{0}'
ChangedMessage=Changed overrideMode for '{0}' to {1}
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
        [String]$SectionName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Allow', 'Deny')]
        [String]$OverrideMode
    )
    
    CheckIISPoshModule

    [string]$oMode = GetOverrideMode -section $SectionName

    if ($oMode -eq $null)
    {
        $ensureResult = 'Absent';
    }
    else
    {        
        if ($oMode -eq $OverrideMode)
        {
            $ensureResult = 'Present'
        }
        else
        {
            $ensureResult = 'Absent';
        }
    }

    # in case the section has not been found, $oMode will be $null
    $getTargetResourceResult = @{SectionName = $SectionName
                                OverrideMode = $oMode
                                      Ensure = $ensureResult}

    
    return $getTargetResourceResult
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function set the OverrideMode for a given section if not already correct
######################################################################################
function Set-TargetResource
{
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

    CheckIISPoshModule
    [string]$oMode = GetOverrideMode -section $SectionName


    if ($oMode -eq 'Allow' -and $OverrideMode -eq 'Deny')
    {
         Set-webconfiguration -Location '' -Filter "/system.webServer/$SectionName" -PSPath 'machine/webroot/apphost' -metadata overrideMode -value Deny
         Write-Verbose($($LocalizedData.ChangedMessage) -f $SectionName,'Deny')
    }
    elseif ($oMode -eq 'Deny' -and $OverrideMode -eq 'Allow')
    {
         Set-webconfiguration -Location '' -Filter "/system.webServer/$SectionName" -PSPath 'machine/webroot/apphost' -metadata overrideMode -value Allow
         Write-Verbose($($LocalizedData.ChangedMessage) -f $SectionName,'Allow')
    }
}

######################################################################################
# The Test-TargetResource cmdlet.
# This will test if the given section has the required OverrideMode
######################################################################################
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

    CheckIISPoshModule

    [string]$oMode = GetOverrideMode -section $SectionName

    if ($oMode -eq $OverrideMode)
    {
        # in this case we have our desired state
        return $true
    }
    else
    {
        # state doesn't match or doesn't exist
        return $false
    }       
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

Function GetOverrideMode([string]$section)
{
    $errorMessage = $($LocalizedData.UnableToGetConfig) -f $section
    if ((Get-WebConfiguration -Location '' -Filter /system.webServer/$section).count -eq 0)
    {        
        Throw $errorMessage;
    }

    [string]$oMode = ((Get-WebConfiguration -Location '' -Filter /system.webServer/$section -metadata).Metadata).effectiveOverrideMode

    # check for a single value.
    # if $oMode is anything but Allow or Deny, we have a problem with our get-webconfiguration call
    # or the ApplicationHost.config file is corrupted, I think its worth stopping here.
    if ($oMode -notmatch "^(Allow|Deny)$")
    {
        Throw $errorMessage
    }

    return $oMode 
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource
