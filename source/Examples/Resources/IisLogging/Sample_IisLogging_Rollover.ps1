configuration Sample_IisLogging_Rollover
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc

    Node $NodeName
    {
        IisLogging Logging
        {
            LogPath              = 'C:\IISLogFiles'
            Logflags             = @('Date', 'Time', 'ClientIP', 'UserName', 'ServerIP')
            LoglocalTimeRollover = $true
            LogPeriod            = 'Hourly'
            LogFormat            = 'W3C'
        }
    }
}
