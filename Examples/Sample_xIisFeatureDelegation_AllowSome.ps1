configuration Sample_IISFeatureDelegation
{
    param
    (
        [Parameter()]
        [string[]]
        $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration
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
        xIisFeatureDelegation serverRuntime
        {
            Filter       = '/system.webserver/serverRuntime'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }

        xIisFeatureDelegation anonymousAuthentication
        {
            Filter       = '/system.webserver/security/authentication/anonymousAuthentication'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }

        xIisFeatureDelegation sessionState
        {
            Filter       = '/system.web/sessionState'
            OverrideMode = 'Allow'
            Path         = 'MACHINE/WEBROOT/APPHOST'
        }
    }
}
