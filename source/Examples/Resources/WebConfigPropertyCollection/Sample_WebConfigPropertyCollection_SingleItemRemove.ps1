<#
.SYNOPSIS
    Removes making appsettings.json inaccessible to clients.

.DESCRIPTION
    This example shows how to use the WebConfigPropertyCollection DSC resource for removing a single item configuration element.
    It will remove the "add" element from the system.webServer/security/requestFiltering/hiddenSegments collection (if present) for blocking appsettings.json.
#>
Configuration Sample_WebConfigPropertyCollection_SingleItemRemove
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
        WebConfigPropertyCollection "$($NodeName) - Remove blocking appsettings.json"
        {
            WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
            Filter            = 'system.webServer/security/requestFiltering'
            CollectionName    = 'hiddenSegments'
            ItemName          = 'add'
            ItemKeyName       = '*'
            ItemKeyValue      = 'appsettings.json'
            ItemPropertyName  = 'segment'
            Ensure            = 'Absent'
        }
    }
}
