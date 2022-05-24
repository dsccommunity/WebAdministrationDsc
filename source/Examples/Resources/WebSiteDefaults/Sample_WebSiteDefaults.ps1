<#
    .SYNOPSIS
        An example of configuring the website default settings.
    .DESCRIPTION
        This examples show how to use WebSiteDefaults for configuring the website default settings.
#>
Configuration Sample_WebSiteDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc

    Node $NodeName
    {
        WebSiteDefaults SiteDefaults
        {
            IsSingleInstance       = 'Yes'
            LogFormat              = 'IIS'
            LogDirectory           = 'C:\inetpub\logs\LogFiles'
            TraceLogDirectory      = 'C:\inetpub\logs\FailedReqLogFiles'
            DefaultApplicationPool = 'DefaultAppPool'
            AllowSubDirConfig      = 'true'
        }
    }
}
