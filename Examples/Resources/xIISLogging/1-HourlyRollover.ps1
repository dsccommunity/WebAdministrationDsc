<#
    .EXAMPLE
    Roll over IIS logs hourly.
#>

configuration Example
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
            LogPath = 'C:\IISLogFiles'
            Logflags = @('Date','Time','ClientIP','UserName','ServerIP')
            LoglocalTimeRollover = $true
            LogPeriod = 'Hourly'
            LogFormat = 'W3C'
        }
    }
}
