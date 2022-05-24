configuration Sample_IisLogging_LogFlags
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
            Logflags             = @('Date', 'Time', 'ClientIP', 'ServerIP', 'UserAgent')
            LogFormat            = 'W3C'
        }
    }
}
