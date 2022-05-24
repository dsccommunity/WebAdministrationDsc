configuration Sample_WebSiteDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc, PSDesiredStateConfiguration

    Node $NodeName
    {
        WebSiteDefaults SiteDefaults
        {
            IsSingleInstance  = 'Yes'
            LogFormat         = 'IIS'
            AllowSubDirConfig = 'true'
        }


        WebAppPoolDefaults PoolDefaults
        {
            IsSingleInstance      = 'Yes'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType          = 'ApplicationPoolIdentity'
        }
    }
}
