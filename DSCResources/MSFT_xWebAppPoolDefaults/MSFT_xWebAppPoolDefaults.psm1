######################################################################################
# DSC Resource for IIS Server level Application Ppol Defaults
# ApplicationHost.config: system.applicationHost/applicationPools
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

    return @{ManagedRuntimeVersion = (GetValue -Path "" -Name "managedRuntimeVersion")
                                    IdentityType = ( GetValue -Path "processModel" -Name "identityType")}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [ValidateSet("Machine")]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        # in the future there will be another CLR version to be allowed 
        [ValidateSet("","v2.0","v4.0")]
        [string]$ManagedRuntimeVersion,
        # TODO: we currently don't allow a custom identity
        [ValidateSet("ApplicationPoolIdentity","LocalService","LocalSystem","NetworkService")]
        [string]$IdentityType
    )

        CheckIISPoshModule

        SetValue -Path "" -Name "managedRuntimeVersion" -NewValue $ManagedRuntimeVersion
        SetValue -Path "processModel" -Name "identityType" -NewValue $IdentityType
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (    
        [ValidateSet("Machine")]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        [ValidateSet("","v2.0","v4.0")]
        [string]$ManagedRuntimeVersion,
        [ValidateSet("ApplicationPoolIdentity","LocalService","LocalSystem","NetworkService")]
        [string]$IdentityType
    )

    CheckIISPoshModule

    if (!(CheckValue -Path "" -Name "managedRuntimeVersion" -NewValue $ManagedRuntimeVersion)) 
    { 
        return $false
    }

    if (!(CheckValue -Path "processModel" -Name "identityType" -NewValue $IdentityType)) 
    { 
        return $false 
    }
    
    return $true
}

######################################################################################
# Helper Functions
######################################################################################

Function CheckValue([string]$path,[string]$name,[string]$newValue)
{

    if (!$newValue)
    {
        # if no new value was specified, we assume this value is okay.        
        return $true
    }

    $existingValue = GetValue -Path $path -Name $name
    if ($existingValue -ne $newValue)
    {
        return $false
    }
    else
    {
        $relPath = $path + "/" + $name
        Write-Verbose($LocalizedData.ValueOk -f $relPath,$newValue);
        return $true
    }   
}

# some internal helper function to do the actual work:

Function SetValue([string]$path,[string]$name,[string]$newValue)
{
    # if the variable doesn't exist, the user doesn't want to change this value
    if (!$newValue)
    {
        return
    }

    $existingValue = GetValue -Path $path -Name $name
    if ($existingValue -ne $newValue)
    {
        if ($path -ne "")
        {
            $path = "/" + $path
        }

        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" -name $name -value "$newValue"
        $relPath = $path + "/" + $name
        Write-Verbose($LocalizedData.SettingValue -f $relPath,$newValue);
    }    
}

Function GetValue([string]$path,[string]$name)
{
    if ($path -ne "")
    {
        $path = "/" + $path
    }

    return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" -name $name
}

Function CheckIISPoshModule
{
    # Check if WebAdministration module is present for IIS cmdlets
    if(!(Get-Module -ListAvailable -Name WebAdministration))
    {
        Throw $LocalizedData.NoWebAdministrationModule
    }
}

Export-ModuleMember -Function *-TargetResource
