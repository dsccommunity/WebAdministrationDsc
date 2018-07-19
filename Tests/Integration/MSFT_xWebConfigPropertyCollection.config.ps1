
Configuration MSFT_xWebConfigPropertyCollection_Add
{
    Import-DscResource -ModuleName xWebAdministration

    node localhost
    {
        xWebConfigPropertyCollection IntegrationTest
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

Configuration MSFT_xWebConfigPropertyCollection_Update
{
    Import-DscResource -ModuleName xWebAdministration

    node localhost
    {
        xWebConfigPropertyCollection IntegrationTest
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

Configuration MSFT_xWebConfigPropertyCollection_Remove
{
    Import-DscResource -ModuleName xWebAdministration

    node localhost
    {
        xWebConfigPropertyCollection IntegrationTest
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

Configuration MSFT_xWebConfigPropertyCollection_Integer
{
    Import-DscResource -ModuleName xWebAdministration

    node localhost
    {
        xWebConfigPropertyCollection IntegrationTest
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
