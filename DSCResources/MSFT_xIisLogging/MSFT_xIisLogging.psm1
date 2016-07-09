# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1"

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        VerboseGetTargetResult                     = Get-Taget has been run.
        VerboseSetTargetUpdateLogPath              = LogPath is not in the desired state and will be updated.
        VerboseSetTargetUpdateLogFlags             = LogFlags do not match and will be updated.
        VerboseSetTargetUpdateLogPeriod            = LogPeriod is not in the desired state and will be updated.
        VerboseSetTargetUpdateLogTruncateSize      = TruncateSize is not in the desired state and will be updated.
        VerboseSetTargetUpdateLoglocalTimeRollover = LoglocalTimeRollover is not in the desired state and will be updated.
        VerboseSetTargetUpdateLogFormat            = LogFormat is not in the desired state and will be updated
        VerboseTestTargetFalseLogPath              = LogPath does match desired state.
        VerboseTestTargetFalseLogFlags             = LogFlags does not match desired state.
        VerboseTestTargetFalseLogPeriod            = LogPeriod does not match desired state.
        VerboseTestTargetFalseLogTruncateSize      = LogTruncateSize does not match desired state.
        VerboseTestTargetFalseLoglocalTimeRollover = LoglocalTimeRollover does not match desired state.
        VerboseTestTargetFalseLogFormat            = LogFormat does not match desired state.
        WarningLogPeriod                           = LogTruncateSize has is an input as will overwrite this desired state.
        WarningIncorrectLogFormat                  = LogFormat is not W3C, as a result LogFlags will not be used. 
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
        [String] $LogPath
                       
    )

        Assert-Module

        $CurrentLogSettings = Get-WebConfiguration `
                                -filter '/system.applicationHost/sites/siteDefaults/Logfile'

        return @{
            LogPath              = $CurrentLogSettings.directory
            LogFlags             = [Array]$CurrentLogSettings.LogExtFileFlags
            LogPeriod            = $CurrentLogSettings.period
            LogTruncateSize      = $CurrentLogSettings.truncateSize
            LoglocalTimeRollover = $CurrentLogSettings.localTimeRollover
            LogFormat            = $CurrentLogSettings.logFormat
        }
        
        Write-Verbose -Message ($LocalizedData.VerboseGetTargetResult)

}

function Set-TargetResource
{
    <#
    .SYNOPSIS
        This will set the desired state
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $LogPath,
        
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        [String[]] $LogFlags,
                
        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String] $LogPeriod,
                
        [ValidateRange('1048576','4294967295')]
        [String] $LogTruncateSize,

        [Boolean] $LoglocalTimeRollover,
        
        [ValidateSet('IIS','W3C','NCSA')]
        [String] $LogFormat
    )
    
        Assert-Module
    
        $CurrentLogState = Get-TargetResource -LogPath $LogPath
        
        # Update LogFormat if needed
        if ($PSBoundParameters.ContainsKey('LogFormat') -and `
            ($LogFormat -ne $CurrentLogState.LogFormat))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFormat)
            Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logfile' `
                -Name logFormat `
                -Value $LogFormat
        }
        
        # Update LogPath if needed
        if ($PSBoundParameters.ContainsKey('LogPath') -and ($LogPath -ne $CurrentLogState.LogPath))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath)
            Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logfile' `
                -Name directory `
                -Value $LogPath
        }
        
        # Update Logflags if needed; also sets logformat to W3C
        if ($PSBoundParameters.ContainsKey('LogFlags') -and `
            (-not (Compare-LogFlags -LogFlags $LogFlags))) 
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name logFormat `
                -Value 'W3C'
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name logExtFileFlags `
                -Value ($LogFlags -join ',')
        }
        
        # Update Log Period if needed
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $CurrentLogState.LogPeriod))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                {
                    Write-Verbose -Message ($LocalizedData.WarningLogPeriod)
                }              
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name period `
                -Value $LogPeriod
        }
        
        # Update LogTruncateSize if needed
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
            ($LogTruncateSize -ne $CurrentLogState.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name truncateSize `
                -Value $LogTruncateSize
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name period `
                -Value 'MaxSize'
        }
        
        # Update LoglocalTimeRollover if needed
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
             ([System.Convert]::ToBoolean($CurrentLogState.LoglocalTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                -Name localTimeRollover `
                -Value $LoglocalTimeRollover
        }    

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
    param
    (
        [Parameter(Mandatory = $true)]
        [String] $LogPath,
        
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        [String[]] $LogFlags,
                
        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        [String] $LogPeriod,
                
        [ValidateRange('1048576','4294967295')]
        [String] $LogTruncateSize,

        [Boolean] $LoglocalTimeRollover,
        
        [ValidateSet('IIS','W3C','NCSA')]
        [String] $LogFormat
    )
    
        Assert-Module

        $CurrentLogState = Get-TargetResource -LogPath $LogPath
        
        # Check LogFormat
        if ($PSBoundParameters.ContainsKey('LogFormat'))
        {
            # Warn if LogFlags are passed in and Current LogFormat is not W3C
            if ($PSBoundParameters.ContainsKey('LogFlags') -and `
                $LogFormat -ne 'W3C')
            {
                Write-Verbose -Message ($LocalizedData.WarningIncorrectLogFormat)
            }
            # Warn if LogFlags are passed in and Desired LogFormat is not W3C
            if($PSBoundParameters.ContainsKey('LogFlags') -and `
                $CurrentLogState.LogFormat -ne 'W3C')
            {
                Write-Verbose -Message ($LocalizedData.WarningIncorrectLogFormat)
            }
            # Check LogFormat 
            if ($LogFormat -ne $CurrentLogState.LogFormat)
            {
                Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFormat)
                return $false 
            }
        }
        
        # Check LogFlags
        if ($PSBoundParameters.ContainsKey('LogFlags') -and `
            (-not (Compare-LogFlags -LogFlags $LogFlags)))  
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFlags)
            return $false
        }
            
        # Check LogPath
        if ($PSBoundParameters.ContainsKey('LogPath') -and `
            ($LogPath -ne $CurrentLogState.LogPath))
        { 
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath)
            return $false 
        }
        
        # Check LogPeriod
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and `
            ($LogPeriod -ne $CurrentLogState.LogPeriod))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
            {
                Write-Verbose -Message ($LocalizedData.WarningLogPeriod)
            }
               
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPeriod)
            return $false   
        }
        
        # Check LogTruncateSize
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and `
            ($LogTruncateSize -ne $CurrentLogState.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTruncateSize)
            return $false
        }
        
        # Check LoglocalTimeRollover
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and `
            ($LoglocalTimeRollover -ne `
             ([System.Convert]::ToBoolean($CurrentLogState.LoglocalTimeRollover))))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLoglocalTimeRollover)
            return $false
        }
        
        return $true

}

#region Helper functions

function Compare-LogFlags
{
    <#
    .SYNOPSIS
        Helper function used to validate that the logflags status.
        Returns False if the loglfags do not match and true if they do
        .PARAMETER LogFlags
        Specifies flags to check
    #>

    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        [String[]] $LogFlags
    )

    $CurrentLogFlags = (Get-WebConfigurationProperty `
                        -Filter '/system.Applicationhost/Sites/SiteDefaults/logfile' `
                        -Name LogExtFileFlags) -split ',' | `
                        Sort-Object

    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags `
                       -DifferenceObject $ProposedLogFlags)
    {
        return $false
    }
    
    return $true

}

#endregion

Export-ModuleMember -function *-TargetResource
