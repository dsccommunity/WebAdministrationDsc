configuration DSC_xIISFeatureDelegation_AllowDelegation
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIisFeatureDelegation AllowDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.web/customErrors'
        OverrideMode = 'Allow'
    }
}

configuration DSC_xIISFeatureDelegation_DenyDelegation
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIisFeatureDelegation DenyDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.webServer/defaultDocument'
        OverrideMode = 'Deny'
    }
}
