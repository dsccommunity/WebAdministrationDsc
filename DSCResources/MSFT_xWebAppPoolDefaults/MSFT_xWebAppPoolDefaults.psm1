# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
NoWebAdministrationModule=Please ensure that WebAdministration module is installed.
SettingValue=Changing default value '{0}' to '{1}'
ValueOk=Default value '{0}' is already '{1}'
VerboseGetTagetResource   = Get-TargetResource has been run.
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
    
    Assert-Module

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    return @{
        ManagedRuntimeVersion = (Get-Value -Path '' -Name 'managedRuntimeVersion')
        IdentityType          = ( Get-Value -Path 'processModel' -Name 'identityType')
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (    
        [ValidateSet('Machine')]
        [parameter(Mandatory = $true)]
        [string]$ApplyTo,

        [ValidateSet('','v2.0','v4.0')]
        [string]$ManagedRuntimeVersion,

        [ValidateSet('ApplicationPoolIdentity','LocalService','LocalSystem','NetworkService')]
        [string]$IdentityType
    )

        Assert-Module

        Set-Value -Path '' -Name 'managedRuntimeVersion' -NewValue $ManagedRuntimeVersion
        Set-Value -Path 'processModel' -Name 'identityType' -NewValue $IdentityType
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
        [string]$IdentityType
    )

    Assert-Module

    if (!(Confirm-Value -Path '' -Name 'managedRuntimeVersion' -NewValue $ManagedRuntimeVersion)) 
    { 
        return $false
    }

    if (!(Confirm-Value -Path 'processModel' -Name 'identityType' -NewValue $IdentityType)) 
    { 
        return $false 
    }
    
    return $true
}

#region Helper Functions

Function Confirm-Value
{
    [CmdletBinding()]
    param
    (  
        [string]$path,
        
        [string]$name,
    
        [string]$newValue
    )
    
    if (!$newValue)
    {
        # if no new value was specified, we assume this value is okay.        
        return $true
    }

    $existingValue = Get-Value -Path $path -Name $name
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

Function Set-Value
{
        [CmdletBinding()]
        param
        (  
            [string]$path,
        
            [string]$name,
    
            [string]$newValue
        )

    # if the variable doesn't exist, the user doesn't want to change this value
    if (!$newValue)
    {
        return
    }

    $existingValue = Get-Value -Path $path -Name $name
    if ($existingValue -ne $newValue)
    {
        if ($path -ne '')
        {
            $path = '/' + $path
        }

        Set-WebConfigurationProperty `
            -pspath 'MACHINE/WEBROOT/APPHOST' `
            -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" `
            -name $name `
            -value "$newValue"
        
        $relPath = $path + '/' + $name
        Write-Verbose($LocalizedData.SettingValue -f $relPath,$newValue);

    }

}

Function Get-Value
{
    
    [CmdletBinding()]
    param
    (  
        [string]$path,
    
        [string]$name
    )

    {
        if ($path -ne '')
        {
            $path = '/' + $path
        }

        return Get-WebConfigurationProperty `
                -pspath 'MACHINE/WEBROOT/APPHOST' ``
                -filter "system.applicationHost/applicationPools/applicationPoolDefaults$path" `
                -name $name
    
    }

}

#endregion

Export-ModuleMember -Function *-TargetResource
