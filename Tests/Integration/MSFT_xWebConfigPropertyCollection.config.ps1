
Configuration MSFT_xWebConfigPropertyCollection_Add
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigPropertyCollection IntegrationTest
    {
        WebsitePath       = $env:xWebConfigPropertyCollectionWebsitePath
        Filter            = $env:xWebConfigPropertyCollectionFilter
        CollectionName    = $env:xWebConfigPropertyCollectionCollectionName
        ItemName          = $env:xWebConfigPropertyCollectionItemName
        ItemKeyName       = $env:xWebConfigPropertyCollectionItemKeyName
        ItemKeyValue      = $env:xWebConfigPropertyCollectionItemKeyValue
        ItemPropertyName  = $env:xWebConfigPropertyCollectionItemPropertyName
        ItemPropertyValue = $env:xWebConfigPropertyCollectionItemPropertyValueAdd
        Ensure            = 'Present'
    }
}

Configuration MSFT_xWebConfigPropertyCollection_Update
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigPropertyCollection IntegrationTest
    {
        WebsitePath       = $env:xWebConfigPropertyCollectionWebsitePath
        Filter            = $env:xWebConfigPropertyCollectionFilter
        CollectionName    = $env:xWebConfigPropertyCollectionCollectionName
        ItemName          = $env:xWebConfigPropertyCollectionItemName
        ItemKeyName       = $env:xWebConfigPropertyCollectionItemKeyName
        ItemKeyValue      = $env:xWebConfigPropertyCollectionItemKeyValue
        ItemPropertyName  = $env:xWebConfigPropertyCollectionItemPropertyName
        ItemPropertyValue = $env:xWebConfigPropertyCollectionItemPropertyValueUpdate
        Ensure            = 'Present'
    }
}

Configuration MSFT_xWebConfigPropertyCollection_Remove
{
    Import-DscResource -ModuleName xWebAdministration

    xWebConfigPropertyCollection IntegrationTest
    {
        WebsitePath       = $env:xWebConfigPropertyCollectionWebsitePath
        Filter            = $env:xWebConfigPropertyCollectionFilter
        CollectionName    = $env:xWebConfigPropertyCollectionCollectionName
        ItemName          = $env:xWebConfigPropertyCollectionItemName
        ItemKeyName       = $env:xWebConfigPropertyCollectionItemKeyName
        ItemKeyValue      = $env:xWebConfigPropertyCollectionItemKeyValue
        ItemPropertyName  = $env:xWebConfigPropertyCollectionItemPropertyName
        Ensure            = 'Absent'
    }
}
