# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        NoWebAdministrationModule = Please ensure that WebAdministration module is installed.
        SettingValue              = Changing default value '{0}' to '{1}'
        ValueOk                   = Default value '{0}' is already '{1}'
        VerboseGetTargetResource  = Get-TargetResource has been run.
'@
}

function Get-TargetResource
{
    <#
    .SYNOPSIS
        This will return a hashtable of results 
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo
    )

    Assert-Module

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource

    return @{
        ManagedRuntimeVersion = (Get-Value -Path '' -Name 'managedRuntimeVersion')
        IdentityType          = (Get-Value -Path 'processModel' -Name 'identityType')
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
        This will set the desired state
    #>

    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo,

        [Parameter()]
        [ValidateSet('','v2.0','v4.0')]
        [System.String]
        $ManagedRuntimeVersion,

        [Parameter()]
        [ValidateSet('ApplicationPoolIdentity','LocalService','LocalSystem','NetworkService')]
        [System.String]
        $IdentityType
    )

    Assert-Module

    Set-Value -Path '' -Name 'managedRuntimeVersion' -NewValue $ManagedRuntimeVersion
    Set-Value -Path 'processModel' -Name 'identityType' -NewValue $IdentityType
}

function Test-TargetResource
{
    <#
    .SYNOPSIS
        This tests the desired state. If the state is not correct it will return $false.
        If the state is correct it will return $true
    #>
    
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSDSCUseVerboseMessageInDSCResource", "")]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Machine')]
        [System.String]
        $ApplyTo,

        [Parameter()]
        [ValidateSet('','v2.0','v4.0')]
        [System.String]
        $ManagedRuntimeVersion,

        [Parameter()]
        [ValidateSet('ApplicationPoolIdentity','LocalService','LocalSystem','NetworkService')]
        [System.String]
        $IdentityType
    )

    Assert-Module

    if (-not((Confirm-Value -Path '' `
                            -Name 'managedRuntimeVersion' `
                            -NewValue $ManagedRuntimeVersion)))
    { 
        return $false
    }

    if (-not((Confirm-Value -Path 'processModel' `
                            -Name 'identityType' `
                            -NewValue $IdentityType)))
    {
        return $false 
    }
    
    return $true
}

#region Helper Functions

function Confirm-Value
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NewValue
    )
    
    if (-not($NewValue))
    {
        # if no new value was specified, we assume this value is okay.
        return $true
    }

    $existingValue = Get-Value -Path $Path -Name $Name
    if ($existingValue -ne $NewValue)
    {
        return $false
    }
    else
    {
        $relPath = $Path + '/' + $Name
        Write-Verbose($LocalizedData.ValueOk -f $relPath,$NewValue);
        return $true
    }
}

function Set-Value
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $NewValue
    )

    # if the variable doesn't exist, the user doesn't want to change this value
    if (-not($NewValue))
    {
        return
    }

    $existingValue = Get-Value -Path $Path -Name $Name
    if ($existingValue -ne $NewValue)
    {
        if ($Path -ne '')
        {
            $Path = '/' + $Path
        }

        Set-WebConfigurationProperty `
            -PSPath 'MACHINE/WEBROOT/APPHOST' `
            -Filter "system.applicationHost/applicationPools/applicationPoolDefaults$Path" `
            -Name $Name `
            -Value "$NewValue"
        
        $relPath = $Path + '/' + $Name
        Write-Verbose($LocalizedData.SettingValue -f $relPath,$NewValue);
    }
}

function Get-Value
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    if ($Path -ne '')
    {
        $Path = '/' + $Path
    }

    $result = Get-WebConfigurationProperty `
                -PSPath 'MACHINE/WEBROOT/APPHOST' `
                -Filter "system.applicationHost/applicationPools/applicationPoolDefaults$Path" `
                -Name $Name

    if ($result -is [Microsoft.IIs.PowerShell.Framework.ConfigurationAttribute])
    {
        return $result.Value
    } else {
        return $result
    }
}

#endregion

Export-ModuleMember -Function *-TargetResource
