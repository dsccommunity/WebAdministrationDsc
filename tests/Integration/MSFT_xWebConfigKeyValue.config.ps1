
configuration MSFT_xWebConfigKeyValue_Config
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigKeyValue IntegrationAppSetting 
    {
        Ensure          = 'Present'
        ConfigSection   = 'AppSettings'
        Key             = $env:xWebConfigKeyValueIntegrationKey
        Value           = 'xWebAdministration Integration Tests Value'
        WebsitePath     = $env:xWebConfigKeyValuePsPath
    }
}

configuration MSFT_xWebConfigKeyValue_AppSetting_Update
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigKeyValue IntegrationAppSetting 
    {
        Ensure          = 'Present'
        ConfigSection   = 'AppSettings'
        Key             = $env:xWebConfigKeyValueIntegrationKey
        Value           = $env:xWebConfigKeyValueIntegrationValueUpdated
        WebsitePath     = $env:xWebConfigKeyValuePsPath
    }
}

configuration MSFT_xWebConfigKeyValue_AppSetting_Absent
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigKeyValue IntegrationAppSetting 
    {
        Ensure          = 'Absent'
        ConfigSection   = 'AppSettings'
        Key             = $env:xWebConfigKeyValueIntegrationKey
        WebsitePath     = $env:xWebConfigKeyValuePsPath
    }
}
