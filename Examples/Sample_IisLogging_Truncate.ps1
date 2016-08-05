configuration Sample_IisLogging_Truncate
{
    param
    (
        # Target nodes to apply the configuration
        [String[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        IisLogging Logging
        {
            LogPath = 'C:\IISLogFiles'
            Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
            LoglocalTimeRollover = $True
            LogTruncateSize = '2097152'
            LogFormat = 'W3C'
        }
    }
}
