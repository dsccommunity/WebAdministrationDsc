######################################################################################
# DSC Resource for IIS Server level Web Site Defaults
# ApplicationHost.config: system.applicationHost/sites/siteDefaults
#
# only a limited number of settings are supported at this time
# We try to cover the most common use cases
# We have a single parameter for each setting
######################################################################################
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
SettingValue=Changing default value '{0}' to '{1}'
ValueOk=Default value '{0}' is already '{1}'
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
        [ValidateSet("Machine")]
        [string]$ApplyTo
	)
	
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    $getTargetResourceResult = $null;

    $getTargetResourceResult = @{LogFormat = (GetValue "siteDefaults/logFile" "logFormat")
                                    TraceLogDirectory = ( GetValue "siteDefaults/traceFailedRequestsLogging" "directory")
                                    DefaultApplicationPool = (GetValue "applicationDefaults" "applicationPool")
                                    AllowSubDirConfig = (GetValue "virtualDirectoryDefaults" "allowSubDirConfig")
                                    ApplyTo = "Machine"
                                    LogDirectory = (GetValue "siteDefaults/logFile" "directory")}    
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
        [ValidateSet("Machine")]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        [ValidateSet("W3C","IIS","NCSA","Custom")]
        [string]$LogFormat,
        [string]$LogDirectory,
        [string]$TraceLogDirectory,
        [string]$DefaultApplicationPool,
        [ValidateSet("true","false")]
        [string]$AllowSubDirConfig
    )

        CheckIISPoshModule

        SetValue "siteDefaults/logFile" "logFormat" $LogFormat
        SetValue "siteDefaults/logFile" "directory" $LogDirectory
        SetValue "siteDefaults/traceFailedRequestsLogging" "directory" $TraceLogDirectory
        SetValue "applicationDefaults" "applicationPool" $DefaultApplicationPool
        SetValue "virtualDirectoryDefaults" "allowSubDirConfig" $AllowSubDirConfig
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
        [ValidateSet("Machine")]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        [ValidateSet("W3C","IIS","NCSA","Custom")]
        [string]$LogFormat,
        [string]$LogDirectory,
        [string]$TraceLogDirectory,
        [string]$DefaultApplicationPool,
        [ValidateSet("true","false")]
        [string]$AllowSubDirConfig
	)

    [bool]$DesiredConfigurationMatch = $true;

    CheckIISPoshModule

    $DesiredConfigurationMatch = CheckValue "virtualDirectoryDefaults" "allowSubDirConfig" $AllowSubDirConfig
    if (!($DesiredConfigurationMatch)) { return $false }

    $DesiredConfigurationMatch = CheckValue "siteDefaults/logFile" "logFormat" $LogFormat
    if (!($DesiredConfigurationMatch)) { return $false }

    $DesiredConfigurationMatch = CheckValue "siteDefaults/logFile" "directory" $LogDirectory
    if (!($DesiredConfigurationMatch)) { return $false }

    $DesiredConfigurationMatch = CheckValue "siteDefaults/traceFailedRequestsLogging" "directory" $TraceLogDirectory
    if (!($DesiredConfigurationMatch)) { return $false }

    $DesiredConfigurationMatch = CheckValue "applicationDefaults" "applicationPool" $DefaultApplicationPool
    if (!($DesiredConfigurationMatch)) { return $false }
    
	return $DesiredConfigurationMatch
}

Function CheckValue([string]$path,[string]$name,[string]$newValue)
{
    if (!$newValue)
    {
        # if no new value was specified, we assume this value is okay.        
        return $true
    }


    [bool]$DesiredConfigurationMatch = $true;

    $existingValue = GetValue $path $name
    if ($existingValue -ne $newValue)
    {
        $DesiredConfigurationMatch = $false
    }
    else
    {
        $relPath = $path + "/" + $name
        Write-Verbose($LocalizedData.ValueOk -f $relPath,$newValue);
    }
    
    return $DesiredConfigurationMatch
}

# some internal helper function to do the actual work:

Function SetValue([string]$path,[string]$name,[string]$newValue)
{
    if ($newValue)
    {
        $existingValue = GetValue $path $name
        if ($existingValue -ne $newValue)
        {
            Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/$path" -name $name -value "$newValue"
            $relPath = $path + "/" + $name
            Write-Verbose($LocalizedData.SettingValue -f $relPath,$newValue);
        }
    }
}

Function GetValue([string]$path,[string]$name)
{
    return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/$path" -name $name
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