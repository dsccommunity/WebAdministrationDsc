# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        NoWebAdministrationModule = Please ensure that WebAdministration module is installed.
        SettingValue              = Changing default value '{0}' to '{1}'
        ValueOk                   = Default value '{0}' is already '{1}'
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
        [String]$ApplyTo
    )
    
    Assert-Module

    Write-Verbose -Message $LocalizedData.VerboseGetTargetResource
    
    return @{
        LogFormat = (Get-Value 'siteDefaults/logFile' 'logFormat')
        TraceLogDirectory = ( Get-Value 'siteDefaults/traceFailedRequestsLogging' 'directory')
        DefaultApplicationPool = (Get-Value 'applicationDefaults' 'applicationPool')
        AllowSubDirConfig = (Get-Value 'virtualDirectoryDefaults' 'allowSubDirConfig')
        ApplyTo = 'Machine'
        LogDirectory = (Get-Value 'siteDefaults/logFile' 'directory')
    }    

}

function Set-TargetResource
{
    <#
        .NOTES
        only a limited number of settings are supported at this time
        We try to cover the most common use cases
        We have a single parameter for each setting
    #>
    [CmdletBinding()]
    param
    (    
        [ValidateSet('Machine')]
        [parameter(Mandatory = $true)]
        [String]$ApplyTo,
        
        [ValidateSet('W3C','IIS','NCSA','Custom')]
        [String]$LogFormat,
        
        [String]$LogDirectory,
        
        [String]$TraceLogDirectory,
        
        [String]$DefaultApplicationPool,
        
        [ValidateSet('true','false')]
        [String]$AllowSubDirConfig
    )

        Assert-Module

        Set-Value 'siteDefaults/logFile' 'logFormat' $LogFormat
        Set-Value 'siteDefaults/logFile' 'directory' $LogDirectory
        Set-Value 'siteDefaults/traceFailedRequestsLogging' 'directory' $TraceLogDirectory
        Set-Value 'applicationDefaults' 'applicationPool' $DefaultApplicationPool
        Set-Value 'virtualDirectoryDefaults' 'allowSubDirConfig' $AllowSubDirConfig

}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (    
        [ValidateSet('Machine')]
        [parameter(Mandatory = $true)]
        [String]$ApplyTo,
        
        [ValidateSet('W3C','IIS','NCSA','Custom')]
        [String]$LogFormat,
        
        [String]$LogDirectory,
        
        [String]$TraceLogDirectory,
        
        [String]$DefaultApplicationPool,
        
        [ValidateSet('true','false')]
        [String]$AllowSubDirConfig
    )

    Assert-Module

    # check for the various given settings:

    if (-not(Confirm-Value -path 'virtualDirectoryDefaults' `
                           -name 'allowSubDirConfig' `
                           -newValue $AllowSubDirConfig)) 
    { 
        return $false 
    }

    if (-not(Confirm-Value -path 'siteDefaults/logFile' `
                           -name 'logFormat' `
                           -newValue $LogFormat)) 
    { 
        return $false 
    }

    if (-not(Confirm-Value -path 'siteDefaults/logFile' `
                           -name 'directory' `
                           -newValue $LogDirectory)) 
    { 
        return $false 
    }

    if (-not(Confirm-Value -path 'siteDefaults/traceFailedRequestsLogging' `
                           -name 'directory' `
                           -newValue $TraceLogDirectory)) 
    { 
        return $false 
    }

    if (-not(Confirm-Value -path 'applicationDefaults' `
                           -name 'applicationPool' `
                           -newValue $DefaultApplicationPool)) 
    { 
        return $false 
    }

    return $true

}

#region Helper Functions
Function Confirm-Value
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [String]$path,

        [String]$name,
        
        [String]$newValue
    )
    
    if (-not($newValue))
    {
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
        [String]$path,

        [String]$name,

        [String]$newValue
    )

    # if the variable doesn't exist, the user doesn't want to change this value
    if (-not($newValue))
    {
        return
    }

    # get the existing value to compare
    $existingValue = Get-Value -Path $path -Name $name
    if ($existingValue -ne $newValue)
    {
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
                                     -filter "system.applicationHost/sites/$path" `
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
        [String]$path,
    
        [String]$name
    )

    return Get-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' `
                                        -filter "system.applicationHost/sites/$path" `
                                        -name $name
}

#endregion

Export-ModuleMember -function *-TargetResource
