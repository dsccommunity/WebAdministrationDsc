configuration Sample_xIisLogging_LogFlags
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xIisLogging Logging
        {
            LogPath              = 'C:\IISLogFiles'
            Logflags             = @('Date', 'Time', 'ClientIP', 'ServerIP', 'UserAgent')
            LogFormat            = 'W3C'
        }
    }
}
