[string] $constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string] $constAPDFilter = 'system.applicationHost/applicationPools/applicationPoolDefaults'
[string] $constSiteFilter = 'system.applicationHost/sites/'

[string] $originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

configuration DSC_xWebAppPoolDefaults_Config
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $originalValue
    }
}

configuration DSC_xWebAppPoolDefaults_ManagedRuntimeVersion
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $env:PesterManagedRuntimeVersion
    }
}

configuration DSC_xWebAppPoolDefaults_AppPoolIdentityType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        IdentityType = $env:PesterApplicationPoolIdentity
    }
}

configuration DSC_xWebAppPoolDefaults_LogFormat
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xWebSiteDefaults LogFormat
    {
        IsSingleInstance = 'Yes'
        LogFormat = $env:PesterLogFormat
    }
}

configuration DSC_xWebAppPoolDefaults_DefaultPool
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xWebSiteDefaults DefaultPool
    {
        IsSingleInstance = 'Yes'
        DefaultApplicationPool = $env:PesterDefaultPool
    }
}
