<#
    .SYNOPSIS
        This example will install the IIS Windows Feature and unlocks the IIS configuration
        sections specified by the Filter setting. This example uses the IIS Configuration Path format
        for the 'Path' setting.
#>
configuration Example
{
    param
    (
        [Parameter()]
        [string[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -Module WebAdministrationDsc
    Import-DscResource -Module PSDesiredStateConfiguration

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Allow Write access to some section that normally don't have it.
        IisFeatureDelegation serverRuntime
        {
            Filter       = '/system.webserver/serverRuntime'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }

        IisFeatureDelegation anonymousAuthentication
        {
            Filter       = '/system.webserver/security/authentication/anonymousAuthentication'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }

        IisFeatureDelegation sessionState
        {
            Filter       = '/system.web/sessionState'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }
    }
}
