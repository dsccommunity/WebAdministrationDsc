<#
    .SYNOPSIS
        This example will install the IIS Windows Feature and unlocks the IIS configuration
        sections specified by the Filter setting.  This example uses the IIS Module Path format
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

    Import-DscResource -Module xWebAdministration
    Import-DscResource -Module PSDscResources

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
            Path         = 'IIS:\Sites\Default Web Site'
        }

        xIisFeatureDelegation anonymousAuthentication
        {
            Filter       = '/system.webserver/security/authentication/anonymousAuthentication'
            OverrideMode = 'Allow'
            Path         = 'IIS:\Sites\Default Web Site'
        }

        xIisFeatureDelegation sessionState
        {
            Filter       = '/system.web/sessionState'
            OverrideMode = 'Allow'
            Path         = 'IIS:\Sites\Default Web Site'
        }
    }
}
