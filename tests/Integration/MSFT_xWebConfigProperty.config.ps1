Configuration MSFT_xWebConfigProperty_Add
{
    Import-DscResource -ModuleName xWebAdministration

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

Configuration MSFT_xWebConfigProperty_Update
{
    Import-DscResource -ModuleName xWebAdministration

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

Configuration MSFT_xWebConfigProperty_Integer
{
    Import-DscResource -ModuleName xWebAdministration

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

Configuration MSFT_xWebConfigProperty_Remove
{
    Import-DscResource -ModuleName xWebAdministration

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
