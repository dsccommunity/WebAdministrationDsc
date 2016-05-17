configuration MSFT_xIisLogging_Rollover
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = 'True'
        LogPeriod = 'Hourly'
    }
}

configuration MSFT_xIisLogging_Truncate
{
    Import-DscResource -ModuleName xWebAdministration

    xIisLogging Logging
    {
        LogPath = 'C:\IISLogFiles'
        Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
        LoglocalTimeRollover = 'True'
        LogTruncateSize = '2097152'
    }
}
