<#
.SYNOPSIS
    Disables the HTTP TRACE method at the server level.

.DESCRIPTION
    This example shows how to use the xWebConfigPropertyCollection DSC resource for adding a configuration element.
    It will add an "add" element to the system.webServer/security/requestFiltering/verbs collection to disable the HTTP TRACE verb.
#>
Configuration Sample_xWebConfigPropertyCollection_Add
{
    param
    (
        # Target nodes to apply the configuration.
        [Parameter()]
        [String[]]
        $NodeName = 'localhost'
    )

    # Import the modules that define custom resources
    Import-DscResource -ModuleName xWebAdministration

    Node $NodeName
    {
        xWebConfigPropertyCollection "$($NodeName) - Disable HTTP TRACE method"
        {
            WebsitePath = 'MACHINE/WEBROOT/APPHOST'
            Filter = 'system.webServer/security/requestFiltering'
            CollectionName = 'verbs'
            ItemName = 'add'
            ItemKeyName = 'verb'
            ItemKeyValue = 'TRACE'
            ItemPropertyName = 'allowed'
            ItemPropertyValue = 'false'
            Ensure = 'Present'
        }
    }
}
