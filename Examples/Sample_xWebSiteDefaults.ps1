<#
    .SYNOPSIS
        An example of configuring the website default settings.
    .DESCRIPTION
        This examples show how to use xWebSiteDefaults for configuring the website default settings.
#>
Configuration Sample_xWebSiteDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xWebSiteDefaults SiteDefaults
        {
            ApplyTo                 = 'Machine'
            LogFormat               = 'IIS'
            LogDirectory            = 'C:\inetpub\logs\LogFiles'
            TraceLogDirectory       = 'C:\inetpub\logs\FailedReqLogFiles'
            DefaultApplicationPool  = 'DefaultAppPool'
            AllowSubDirConfig       = 'true'
        }
    }
}
