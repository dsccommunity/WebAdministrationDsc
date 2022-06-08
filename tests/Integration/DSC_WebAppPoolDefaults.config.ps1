[string] $constPsPath = 'MACHINE/WEBROOT/APPHOST'
[string] $constAPDFilter = 'system.applicationHost/applicationPools/applicationPoolDefaults'
[string] $constSiteFilter = 'system.applicationHost/sites/'

[string] $originalValue = (Get-WebConfigurationProperty -pspath $constPsPath -filter $constAPDFilter -name managedRuntimeVersion).Value

configuration DSC_WebAppPoolDefaults_Config
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $originalValue
    }
}

configuration DSC_WebAppPoolDefaults_ManagedRuntimeVersion
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        ManagedRuntimeVersion = $env:PesterManagedRuntimeVersion
    }
}

configuration DSC_WebAppPoolDefaults_AppPoolIdentityType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebAppPoolDefaults PoolDefaults
    {
        IsSingleInstance = 'Yes'
        IdentityType = $env:PesterApplicationPoolIdentity
    }
}

configuration DSC_WebAppPoolDefaults_LogFormat
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebSiteDefaults LogFormat
    {
        IsSingleInstance = 'Yes'
        LogFormat = $env:PesterLogFormat
    }
}

configuration DSC_WebAppPoolDefaults_DefaultPool
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebSiteDefaults DefaultPool
    {
        IsSingleInstance = 'Yes'
        DefaultApplicationPool = $env:PesterDefaultPool
    }
}
