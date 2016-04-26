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
        [ValidateSet('Machine')]
        [string]$ApplyTo
    )
    
    # Check if WebAdministration module is present for IIS cmdlets
    CheckIISPoshModule

    return @{ManagedRuntimeVersion = (GetValue -Path '' -Name 'managedRuntimeVersion')
                                    IdentityType = ( GetValue -Path 'processModel' -Name 'identityType')
                                    autoStart = ( GetValue -Path '' -Name 'autoStart')
                                    enable32BitAppOnWin64 = ( GetValue -Path '' -Name 'enable32BitAppOnWin64')
                                    managedPipelineMode = ( GetValue -Path '' -Name 'managedPipelineMode')
                                    idleTimeout = ( GetValue -Path 'processModel' -Name 'idleTimeout')
                                    shutdownTimeLimit = ( GetValue -Path 'processModel' -Name 'shutdownTimeLimit')
                                    logEventOnRecycle = ( GetValue -Path 'recycling' -Name 'logEventOnRecycle')
                                    restartMemoryLimit = ( GetValue -Path 'recycling/periodicRestart' -Name 'memory')
                                    restartTimeLimit = ( GetValue -Path 'recycling/periodicRestart' -Name 'time')}
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [ValidateSet('Machine')]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        # in the future there will be another CLR version to be allowed 
        [ValidateSet('','v2.0','v4.0')]
        [string]$ManagedRuntimeVersion,
        # TODO: we currently don't allow a custom identity
        [ValidateSet('ApplicationPoolIdentity','LocalService','LocalSystem','NetworkService')]
        [string]$IdentityType,
        [ValidateSet('True','False')]
        [string] $autoStart,
        [ValidateSet('True','False')]
        [string] $enable32BitAppOnWin64,
        [ValidateSet('Classic','Integrated')]
        [string] $managedPipelineMode,
        #Format 00:20:00
        [string] $idleTimeout,
        #Format 00:20:00
        [string] $shutdownTimeLimit,
        [string] $logEventOnRecycle,
        [string] $restartMemoryLimit,
        [string] $restartTimeLimit
    )

        CheckIISPoshModule

        SetValue -Path '' -Name 'managedRuntimeVersion' -NewValue $ManagedRuntimeVersion
        SetValue -Path 'processModel' -Name 'identityType' -NewValue $IdentityType

        SetValue -Path '' -Name 'autoStart' -NewValue $autoStart
        SetValue -Path '' -Name 'enable32BitAppOnWin64' -NewValue 'false'
        SetValue -Path '' -Name 'managedPipelineMode' -NewValue $managedPipelineMode
        SetValue -Path 'processModel' -Name 'idleTimeout' -NewValue $idleTimeout
        SetValue -Path 'processModel' -Name 'shutdownTimeLimit' -NewValue $shutdownTimeLimit
        SetValue -Path 'recycling' -Name 'logEventOnRecycle' -NewValue $logEventOnRecycle

        SetValue -Path 'recycling/periodicRestart' -Name 'memory' -NewValue $restartMemoryLimit
        SetValue -Path 'recycling/periodicRestart' -Name 'time' -NewValue $restartTimeLimit
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (    
        [ValidateSet('Machine')]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,
        [ValidateSet('','v2.0','v4.0')]
        [string]$ManagedRuntimeVersion,
        [ValidateSet('ApplicationPoolIdentity','LocalService','LocalSystem','NetworkService')]
        [string]$IdentityType,
        [ValidateSet('True','False')]
        [string] $autoStart,
        [ValidateSet('True','False')]
        [string] $enable32BitAppOnWin64,
        [ValidateSet('Classic','Integrated')]
        [string] $managedPipelineMode,
        #Format 00:20:00
        [string] $idleTimeout = '00:00:00',
        #Format 00:20:00
        [string] $shutdownTimeLimit,
        [string] $logEventOnRecycle,
        [string] $restartMemoryLimit,
        [string] $restartTimeLimit
    )

    CheckIISPoshModule

    if (!(CheckValue -Path '' -Name 'managedRuntimeVersion' -NewValue $ManagedRuntimeVersion)) 
    { 
        return $false
    }

    if (!(CheckValue -Path 'processModel' -Name 'identityType' -NewValue $IdentityType)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path '' -Name 'autoStart' -NewValue $autoStart)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path '' -Name 'enable32BitAppOnWin64' -NewValue $enable32BitAppOnWin64)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path '' -Name 'managedPipelineMode' -NewValue $managedPipelineMode)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path 'processModel' -Name 'idleTimeout' -NewValue $idleTimeout)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path 'processModel' -Name 'shutdownTimeLimit' -NewValue $shutdownTimeLimit)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path 'recycling' -Name 'logEventOnRecycle' -NewValue $logEventOnRecycle)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path 'recycling/periodicRestart' -Name 'memory' -NewValue $restartMemoryLimit)) 
    { 
        return $false 
    }

    if (!(CheckValue -Path 'recycling/periodicRestart' -Name 'time' -NewValue $restartTimeLimit)) 
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
        $relPath = $path + '/' + $name
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
        
        if ($path -ne '')
        {
            $path = '/' + $path
        }

        $existingValueType = GetValueType -path $path -name $name
        
        if ($existingValueType -eq 'System.Boolean') {
        
            $setNewValue = $newValue
        
        } else {
            
            $setNewValue = $newValue -as $existingValueType.ToString()
            
        }    
        
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" -name $name -value $setNewValue
        $relPath = $path + '/' + $name
        Write-Verbose($LocalizedData.SettingValue -f $relPath,$newValue);
    }    
}

Function GetValue([string]$path,[string]$name)
{
    if ($path -ne '')
    {
        $path = '/' + $path
    }

    return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" -name $name
}

Function GetValueType([string]$path,[string]$name)
{
    if ($path -ne '')
    {
        $path = '/' + $path
    }

    $existingValue = Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" -name $name
    
    if ($existingValue.TypeName) {
        return $existingValue.TypeName
    } elseif ($existingValue.GetTypeCode()) {
        return $existingValue.GetTypeCode()
    } else {
        return ($existingValue.value.GetType()).Name
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

Export-ModuleMember -Function *-TargetResource
