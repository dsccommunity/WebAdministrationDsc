Configuration DSC_xWebConfigProperty_Add
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        xWebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Value        = $Node.AddValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_xWebConfigProperty_Update
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        xWebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Value        = $Node.UpdateValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_xWebConfigProperty_Integer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        xWebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.IntegerFilter
            PropertyName = $Node.IntergerPropertyName
            Value        = $Node.IntegerValue
            Ensure       = 'Present'
        }
    }
}

Configuration DSC_xWebConfigProperty_Remove
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        xWebConfigProperty IntegrationTest
        {
            WebsitePath  = $Node.WebsitePath
            Filter       = $Node.Filter
            PropertyName = $Node.PropertyName
            Ensure       = 'Absent'
        }
    }
}
