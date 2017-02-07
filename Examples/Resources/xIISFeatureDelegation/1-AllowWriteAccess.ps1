<#
    .EXAMPLE
    Allow Write access to some section that normally don't have it.
#>

configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost'
    )

    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xIisFeatureDelegation serverRuntime
        {
            SectionName  = 'serverRuntime'
            OverrideMode = 'Allow'
        }

        xIisFeatureDelegation anonymousAuthentication
        {
            SectionName  = 'security/authentication/anonymousAuthentication'
            OverrideMode = 'Allow'
        }

        xIisFeatureDelegation ipSecurity
        {
            SectionName  = 'security/ipSecurity'
            OverrideMode = 'Allow'
        }
    }
}
