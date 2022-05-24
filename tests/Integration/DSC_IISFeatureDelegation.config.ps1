configuration DSC_IisFeatureDelegation_AllowDelegation
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisFeatureDelegation AllowDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.web/customErrors'
        OverrideMode = 'Allow'
    }
}

configuration DSC_IisFeatureDelegation_DenyDelegation
{
    Import-DscResource -ModuleName WebAdministrationDsc

    IisFeatureDelegation DenyDelegation
    {
        Path = 'MACHINE/WEBROOT/APPHOST'
        Filter = '/system.webServer/defaultDocument'
        OverrideMode = 'Deny'
    }
}
