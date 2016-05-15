#requires -Version 4.0 -Modules CimCmdlets

# Load the Helper Module
Import-Module -Name "$PSScriptRoot\..\Helper.psm1" -Verbose:$false

# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
VerboseSetTargetUpdateLogPath = LogPath does not match and will be updated.
VerboseSetTargetUpdateLogFlags = LogFlags do not match and will be updated.
VerboseSetTargetUpdateLogPeriod = LogPeriod does not match and will be updated.
VerboseSetTargetUpdateLogTruncateSize = TruncateSize does not match and will be updated.
VerboseSetTargetUpdateLoglocalTimeRollover = LoglocalTimeRollover does not match and will be updated.
VerboseTestTargetFalseLogPath = LogPath does match desired state.
VerboseTestTargetFalseLogFlags = LogFlags does not match desired state.
VerboseTestTargetFalseLogPeriod = LogPeriod does not match desired state.
VerboseTestTargetFalseLogTruncateSize = LogTruncateSize does not match desired state.
VerboseTestTargetFalseLoglocalTimeRollover = LoglocalTimeRollover does not match desired state.
WarningLogPeriod = LogTruncateSize has is an input as will overwrite this desired state.
ErrorWebsiteLogFormat = LogFields are not possible when LogFormat is not W3C.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $LogPath,
        
        [Parameter()]
        [String[]]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags,
        
        [Parameter()]
        [String]
        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        $LogPeriod,
        
        [Parameter()]
        [String]
        [ValidateRange('1048576','4294967295')]
        $LogTruncateSize,
        
        [String]
        [ValidateSet('True', 'False')]
        $LoglocalTimeRollover
        
    )

    Assert-Module

        $CurrentLogSettings = Get-WebConfiguration -filter '/system.applicationHost/sites/siteDefaults/Logfile'

        return @{
            LogPath              = $CurrentLogSettings.directory
            LogFlags             = $CurrentLogSettings.LogExtFileFlags
            LogFormat            = $CurrentLogSettings.logFormat
            LogPeriod            = $CurrentLogSettings.period
            LogtruncateSize      = $CurrentLogSettings.truncateSize
            LoglocalTimeRollover = $CurrentLogSettings.localTimeRollover
        }

}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $LogPath,

        [Parameter()]
        [String[]]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags,
        
        [Parameter()]
        [String]
        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        $LogPeriod,
        
        [Parameter()]
        [String]
        [ValidateRange('1048576','4294967295')]
        $LogTruncateSize,
        
        [String]
        [ValidateSet('True', 'False')]
        $LoglocalTimeRollover
    )
    
        Assert-Module
    
        $CurrentLogState = Get-TargetResource -LogPath $LogPath
    
        if ($PSBoundParameters.ContainsKey('LogPath') -and ($LogPath -ne $CurrentLogState.LogPath))
        {
            
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPath)
            Set-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults/logfile' -name directory -value $LogPath
        }
        
        if ($PSBoundParameters.ContainsKey('LogFlags') -and (-not (Compare-LogFlags -LogFlags $LogFlags))) 
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogFlags)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags -Value $LogFlags
        }
        
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and ($LogPeriod -ne $CurrentLogState.LogPeriod))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
                {
                    Write-Verbose -Message ($LocalizedData.WarningLogPeriod)
                }
              
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogPeriod)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name period -Value $LogPeriod
        }
        
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and ($LogTruncateSize -ne $CurrentLogState.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLogTruncateSize)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name truncateSize -Value $LogTruncateSize
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name period -Value 'MaxSize'
        }

        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and ($LoglocalTimeRollover -ne $CurrentLogState.LoglocalTimeRollover))
        {
            Write-Verbose -Message ($LocalizedData.VerboseSetTargetUpdateLoglocalTimeRollover)
            Set-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name localTimeRollover -Value $LoglocalTimeRollover
        }    

}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]
        $LogPath,

        [Parameter()]
        [String[]]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags,
        
        [Parameter()]
        [String]
        [ValidateSet('Hourly','Daily','Weekly','Monthly','MaxSize')]
        $LogPeriod,
        
        [Parameter()]
        [String]
        [ValidateRange('1048576','4294967295')]
        $LogTruncateSize,
        
        [String]
        [ValidateSet('True', 'False')]
        $LoglocalTimeRollover
    )
    
        Assert-Module

        $CurrentLogState = Get-TargetResource -LogPath $LogPath
               
        if ($PSBoundParameters.ContainsKey('LogPath') -and ($LogPath -ne $CurrentLogState.LogPath))
        { 
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPath)
            return $false 
        }
        
        if ($PSBoundParameters.ContainsKey('LogFlags') -and (-not (Compare-LogFlags -LogFlags $LogFlags)))  
        {
            if ($CurrentLogState.logFormat -ne 'W3C')
            {
                    $ErrorMessage = ($LocalizedData.ErrorWebsiteLogFormat)
                    New-TerminatingError -ErrorId 'LogFormatFailure' -ErrorMessage $ErrorMessage -ErrorCategory 'InvalidOperation'
            }
            
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogFlags)
            return $false
        }
        
        if ($PSBoundParameters.ContainsKey('LogPeriod') -and ($LogPeriod -ne $CurrentLogState.LogPeriod))
        {
            if ($PSBoundParameters.ContainsKey('LogTruncateSize'))
            {
                Write-Verbose -Message ($LocalizedData.WarningLogPeriod)
            }
               
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogPeriod)
            return $false   
        }
        
        if ($PSBoundParameters.ContainsKey('LogTruncateSize') -and ($LogTruncateSize -ne $CurrentLogState.LogTruncateSize))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLogTruncateSize)
            return $false
        }
        
        if ($PSBoundParameters.ContainsKey('LoglocalTimeRollover') -and ($LoglocalTimeRollover -ne $CurrentLogState.LoglocalTimeRollover))
        {
            Write-Verbose -Message ($LocalizedData.VerboseTestTargetFalseLoglocalTimeRollover)
            return $false
        }
        
        return $true

}

#region Helper Functions

Function Compare-LogFlags
{

    param
    (
        [Parameter()]
        [String[]]
        [ValidateSet('Date','Time','ClientIP','UserName','SiteName','ComputerName','ServerIP','Method','UriStem','UriQuery','HttpStatus','Win32Status','BytesSent','BytesRecv','TimeTaken','ServerPort','UserAgent','Cookie','Referer','ProtocolVersion','Host','HttpSubStatus')]
        $LogFlags
    )

    $CurrentLogFlags = (Get-WebConfigurationProperty '/system.Applicationhost/Sites/SiteDefaults/logfile' -Name LogExtFileFlags) -split ',' | Sort-Object
    $ProposedLogFlags = $LogFlags -split ',' | Sort-Object

    if (Compare-Object -ReferenceObject $CurrentLogFlags -DifferenceObject $ProposedLogFlags)
    {
        return $false
    }
    
    return $true

}

#endregion

Export-ModuleMember -Function *-TargetResource
