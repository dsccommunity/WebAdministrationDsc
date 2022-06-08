Configuration DSC_WebConfigProperty_Add
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Value        = $Node.AddValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_WebConfigProperty_Update
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Value        = $Node.UpdateValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_WebConfigProperty_Integer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.IntegerFilter
            PropertyName = $Node.IntergerPropertyName
            Value        = $Node.IntegerValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_WebConfigProperty_Remove
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Ensure       = 'Absent'
        }
    }
}
