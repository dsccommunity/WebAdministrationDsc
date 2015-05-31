######################################################################################
# DSC Resource for IIS Server level Web Site Defaults
# ApplicationHost.config: system.applicationHost/sites/siteDefaults
######################################################################################
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
SettingValue=Changing default value '{0}' to '{1}'
'@
}

######################################################################################
# The Get-TargetResource cmdlet.
# This function will get all supported site default values
######################################################################################
function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
        [Parameter(Mandatory)]
        [string]$Scope,
        [string]$LogFormat,
        [string]$LogDirectory,
        [string]$TraceLogDirectory,
        [string]$DefaultApplicationPool,
        [string]$AllowSubDirConfig
	)
	
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    $getTargetResourceResult = $null;

    $getTargetResourceResult = @{LogFormat = (GetValue "logFile" "logFormat")
                                    TraceLogDirectory = ""
                                    DefaultApplicationPool = ""
                                    AllowSubDirConfig = ""
                                    Scope = "Machine"
                                    LogDirectory = ""}    
	return $getTargetResourceResult
}

######################################################################################
# The Set-TargetResource cmdlet.
# This function will change a default setting if not already set
######################################################################################
function Set-TargetResource
{
	param
	(	
        [Parameter(Mandatory)]
        [string]$Scope,
        [string]$LogFormat,
        [string]$LogDirectory,
        [string]$TraceLogDirectory,
        [string]$DefaultApplicationPool,
        [string]$AllowSubDirConfig
    )

        CheckIISPoshModule

        SetValue "logFile" "logFormat" $LogFormat
}

######################################################################################
# The Test-TargetResource cmdlet.
# This will test whether all given values are already set in the current configuration
######################################################################################
function Test-TargetResource
{
    [OutputType([System.Boolean])]
	param
	(	
        [Parameter(Mandatory)]
        [string]$Scope,
        [string]$LogFormat,
        [string]$LogDirectory,
        [string]$TraceLogDirectory,
        [string]$DefaultApplicationPool,
        [string]$AllowSubDirConfig
	)

    [bool]$DesiredConfigurationMatch = $true;

    CheckIISPoshModule

    $DesiredConfigurationMatch = CheckValue "logFile" "logFormat" $LogFormat
    if (!($DesiredConfigurationMatch)) { return false }
    
	return $DesiredConfigurationMatch
}

Function CheckValue([sting]$path,[string]$name,[string]$newValue)
{
    [bool]$DesiredConfigurationMatch = $true;
    if ($newValue -ne $null)
    {
        $existingValue = GetValue $path $name
        if ($existingValue -ne $newValue)
        {
            $DesiredConfigurationMatch = $false
        }
        else
        {
            # Write-Verbose "OK"
        }
    }

    return $DesiredConfigurationMatch
}

Function SetValue([sting]$path,[string]$name,[string]$newValue)
{
    if ($newValue -ne $null)
    {
        $existingValue = GetValue $path $name
        if ($existingValue -ne $newValue)
        {
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/$path" -name $name -value "$newValue"
            $relPath = $path + "/" + $name
            WWrite-Verbose($LocalizedData.SettingValue -f $relPath,$newValue);
        }
        else
        {
            # Write-Verbose "OK"
        }
    }
}

Function GetValue([sting]$path,[string]$name)
{
    return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/$path" -name $name
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

#  FUNCTIONS TO BE EXPORTED 
Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource