######################################################################################
# DSC Resource for IIS Server level Feature Delegation
######################################################################################

data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
UnableToGetConfig=Unable to get configuration data for '{0}'
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
        [ValidateSet("Allow", "Deny")]
        [String]$OverrideMode
	)
	
    CheckIISPoshModule

    $getTargetResourceResult = $null;

    [string]$oMode = GetOverrideMode $SectionName

    if ($oMode -eq $null)
    {
        $ensureResult = "Absent";
    }
    else
    {
        $ensureResult = "Present"
        $getTargetResourceResult = @{SectionName = $SectionName
                                    OverrideMode = $oMode}
    }

    
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
        [ValidateSet("Allow", "Deny")]
        [String]$OverrideMode
    )

    CheckIISPoshModule
    [string]$oMode = GetOverrideMode $SectionName


    if ($oMode -eq "Allow" -and $OverrideMode -eq "Deny")
    {
         Set-webconfiguration -Location "" -Filter "/system.webServer/$SectionName" -PSPath "machine/webroot/apphost" -metadata overrideMode -value Deny
         Write-Verbose("Changed overrideMode for $SectionName to Deny");
    }
    elseif ($oMode -eq "Deny" -and $OverrideMode -eq "Allow")
    {
         Set-webconfiguration -Location "" -Filter "/system.webServer/$SectionName" -PSPath "machine/webroot/apphost" -metadata overrideMode -value Allow
         Write-Verbose("Changed overrideMode for $SectionName to Allow");
    }
    else
    {
        Write-Verbose("What's going on here? - $oMode");
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
        [ValidateSet("Allow", "Deny")]
        [String]$OverrideMode
	)

    CheckIISPoshModule

    [bool]$DesiredConfigurationMatch = $true;
    [string]$oMode = GetOverrideMode $SectionName

    if ($oMode -eq $OverrideMode)
    {
        $DesiredConfigurationMatch = $true;
    }
    elseif ($oMode -ne $null -and $OverrideMode -ne $oMode)
    {
        $DesiredConfigurationMatch = $false;
    }
    else
    {
        Write-Verbose("No configuration data found for $SectionName");
        $DesiredConfigurationMatch = $false;
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

Function GetOverrideMode([string]$section)
{
    $errorMessage = $($LocalizedData.UnableToGetConfig) -f $section
    if ((get-webconfiguration -Location "" -Filter /system.webServer/$section).count -eq 0)
    {        
        Throw $errorMessage;
    }

    [string]$oMode = ((get-webconfiguration -Location "" -Filter /system.webServer/$section -metadata).Metadata).effectiveOverrideMode

    # check for a single value.
    if ($oMode -notmatch "^(Allow|Deny)$")
    {
        Throw $errorMessage
    }

    return $oMode 
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource