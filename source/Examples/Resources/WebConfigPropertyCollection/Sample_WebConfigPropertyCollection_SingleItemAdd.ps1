<#
.SYNOPSIS
    Make appsettings.json inaccessible to clients.

.DESCRIPTION
    This example shows how to use the WebConfigPropertyCollection DSC resource for adding a single item configuration element.
    It will add an "add" element to the system.webServer/security/requestFiltering/hiddenSegments collection to block appsettings.json.
#>
Configuration Sample_WebConfigPropertyCollection_SingleItemAdd
{
    param
    (
        # Target nodes to apply the configuration.
        [Parameter()]
        [String[]]
        $NodeName = 'localhost'
    )

    # Import the modules that define custom resources
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $NodeName
    {
        WebConfigPropertyCollection "$($NodeName) - Block appsettings.json"
        {
            WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
            Filter            = 'system.webServer/security/requestFiltering'
            CollectionName    = 'hiddenSegments'
            ItemName          = 'add'
            ItemKeyName       = '*'
            ItemKeyValue      = 'appsettings.json'
            ItemPropertyName  = 'segment'
            ItemPropertyValue = 'appsettings.json'
            Ensure            = 'Present'
        }
    }
}
