configuration MSFT_xIISFeatureDelegation_AllowDelegation
{
    Import-DscResource -ModuleName xWebAdministration

    xIisFeatureDelegation AllowDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.web/customErrors'
        OverrideMode = 'Allow'
    }
}

configuration MSFT_xIISFeatureDelegation_DenyDelegation
{
    Import-DscResource -ModuleName xWebAdministration

    xIisFeatureDelegation DenyDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.webServer/defaultDocument'
        OverrideMode = 'Deny'
    }
}
