configuration MSFT_xIisLogging_Rollover
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogPeriod = 'Hourly'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields  = @(
            MSFT_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            MSFT_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration MSFT_xIisLogging_Truncate
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            MSFT_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            MSFT_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration MSFT_xIisLogging_LogFlags
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','ServerIP','UserAgent')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            MSFT_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            MSFT_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration MSFT_xIisLogging_LogCustomFields
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','ServerIP','UserAgent')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            MSFT_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
                Ensure       = 'Absent'
            }
            MSFT_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
                Ensure       = 'Absent'
            }
        )
    }
}
