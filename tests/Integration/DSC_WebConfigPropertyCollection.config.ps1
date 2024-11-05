
Configuration DSC_WebConfigPropertyCollection_Add
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.Filter
            CollectionName    = $Node.CollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.ItemKeyName
            ItemKeyValue      = $Node.ItemKeyValue
            ItemPropertyName  = $Node.ItemPropertyName
            ItemPropertyValue = $Node.ItemPropertyValueAdd
            Ensure            = 'Present'
        }
    }
}

Configuration DSC_WebConfigPropertyCollection_Update
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.Filter
            CollectionName    = $Node.CollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.ItemKeyName
            ItemKeyValue      = $Node.ItemKeyValue
            ItemPropertyName  = $Node.ItemPropertyName
            ItemPropertyValue = $Node.ItemPropertyValueUpdate
            Ensure            = 'Present'
        }
    }
}

Configuration DSC_WebConfigPropertyCollection_Remove
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.Filter
            CollectionName    = $Node.CollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.ItemKeyName
            ItemKeyValue      = $Node.ItemKeyValue
            ItemPropertyName  = $Node.ItemPropertyName
            Ensure            = 'Absent'
        }
    }
}

Configuration DSC_WebConfigPropertyCollection_Integer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.IntegerFilter
            CollectionName    = $Node.IntegerCollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.IntegerItemKeyName
            ItemKeyValue      = $Node.IntegerItemKeyValue
            ItemPropertyName  = $Node.IntegerItemPropertyName
            ItemPropertyValue = $Node.IntegerItemPropertyValue
            Ensure            = 'Present'
        }
    }
}

Configuration DSC_WebConfigPropertyCollection_SingleItemAdd
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.SingleItemFilter
            CollectionName    = $Node.SingleItemCollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.SingleItemKeyName
            ItemKeyValue      = $Node.SingleItemKeyValue
            ItemPropertyName  = $Node.SingleItemPropertyName
            ItemPropertyValue = $Node.SingleItemPropertyValue
            Ensure            = 'Present'
        }
    }
}

Configuration DSC_WebConfigPropertyCollection_SingleItemRemove
{
    Import-DscResource -ModuleName WebAdministrationDsc

    node localhost
    {
        WebConfigPropertyCollection IntegrationTest
        {
            WebsitePath       = $Node.WebsitePath
            Filter            = $Node.SingleItemFilter
            CollectionName    = $Node.SingleItemCollectionName
            ItemName          = $Node.ItemName
            ItemKeyName       = $Node.SingleItemKeyName
            ItemKeyValue      = $Node.SingleItemKeyValue
            ItemPropertyName  = $Node.SingleItemPropertyName
            Ensure            = 'Absent'
        }
    }
}
