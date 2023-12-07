configuration DSC_IisLogging_Rollover
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogPeriod = 'Hourly'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields  = @(
            DSC_LogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_LogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration DSC_IisLogging_Truncate
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            DSC_LogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_LogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration DSC_IisLogging_LogFlags
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','ServerIP','UserAgent')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            DSC_LogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
            }
            DSC_LogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
            }
        )
    }
}

configuration DSC_IisLogging_LogCustomFields
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','ServerIP','UserAgent')
        LoglocalTimeRollover = $true
        LogTruncateSize = '2097152'
        LogFormat = 'W3C'
        LogTargetW3C = 'File,ETW'
        LogCustomFields    = @(
            DSC_LogCustomField
            {
                LogFieldName = 'ClientEncoding'
                SourceName   = 'Accept-Encoding'
                SourceType   = 'RequestHeader'
                Ensure       = 'Absent'
            }
            DSC_LogCustomField
            {
                LogFieldName = 'X-Powered-By'
                SourceName   = 'ASP.NET'
                SourceType   = 'ResponseHeader'
                Ensure       = 'Absent'
            }
        )
    }
}
