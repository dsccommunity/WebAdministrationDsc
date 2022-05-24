configuration DSC_xIisLogging_Rollover
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogPeriod = 'Hourly'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields  = @(
            DSC_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration DSC_xIisLogging_Truncate
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            DSC_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration DSC_xIisLogging_LogFlags
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','ServerIP','UserAgent')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            DSC_xLogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_xLogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}