Configuration MSFT_xWebConfigProperty_Add
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigProperty IntegrationTest
    {
        WebsitePath  = $env:xWebConfigPropertyWebsitePath
        Filter       = $env:xWebConfigPropertyFilter
        PropertyName = $env:xWebConfigPropertyPropertyName
        Value        = $env:xWebConfigPropertyPropertyValueAdd
        Ensure       = 'Present'
    }
}

Configuration MSFT_xWebConfigProperty_Update
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigProperty IntegrationTest
    {
        WebsitePath  = $env:xWebConfigPropertyWebsitePath
        Filter       = $env:xWebConfigPropertyFilter
        PropertyName = $env:xWebConfigPropertyPropertyName
        Value        = $env:xWebConfigPropertyPropertyValueUpdate
        Ensure       = 'Present'
    }
}

Configuration MSFT_xWebConfigProperty_Remove
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigProperty IntegrationTest
    {
        WebsitePath  = $env:xWebConfigPropertyWebsitePath
        Filter       = $env:xWebConfigPropertyFilter
        PropertyName = $env:xWebConfigPropertyPropertyName
        Ensure       = 'Absent'
    }
}
