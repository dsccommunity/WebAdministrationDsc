[string] $constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string] $constAPDFilter = 'system.applicationHost/applicationPools/applicationPoolDefaults'
[string] $constSiteFilter = 'system.applicationHost/sites/'

[string] $originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

configuration MSFT_xWebAppPoolDefaults_Config
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $originalValue
    }
}

configuration MSFT_xWebAppPoolDefaults_ManagedRuntimeVersion
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $env:PesterManagedRuntimeVersion
    }
}

configuration MSFT_xWebAppPoolDefaults_AppPoolIdentityType
{
    Import-DscResource -ModuleName xWebAdministration

    xWebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        IdentityType = $env:PesterApplicationPoolIdentity
    }
}

configuration MSFT_xWebAppPoolDefaults_LogFormat
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults LogFormat
    {
        IsSingleInstance = 'Yes'
        LogFormat = $env:PesterLogFormat
    }
}

configuration MSFT_xWebAppPoolDefaults_DefaultPool
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults DefaultPool
    {
        IsSingleInstance = 'Yes'
        DefaultApplicationPool = $env:PesterDefaultPool
    }
}
