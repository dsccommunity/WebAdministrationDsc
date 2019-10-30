configuration Sample_xIISServerDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node $NodeName
    {
        xWebSiteDefaults SiteDefaults
        {
            IsSingleInstance  = 'Yes'
            LogFormat         = 'IIS'
            AllowSubDirConfig = 'true'
        }


        xWebAppPoolDefaults PoolDefaults
        {
            IsSingleInstance      = 'Yes'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType          = 'ApplicationPoolIdentity'
        }
    }
}
