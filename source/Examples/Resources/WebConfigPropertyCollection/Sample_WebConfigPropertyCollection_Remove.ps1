<#
.SYNOPSIS
    Removes disabling the HTTP TRACE method at the server level.

.DESCRIPTION
    This example shows how to use the WebConfigPropertyCollection DSC resource for removing a configuration element.
    It will remove the "add" element from the system.webServer/security/requestFiltering/verbs collection (if present) for disabling the HTTP TRACE verb.
#>
Configuration Sample_WebConfigPropertyCollection_Remove
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
        WebConfigPropertyCollection "$($NodeName) - Remove disabling HTTP TRACE method"
        {
            WebsitePath       = 'MACHINE/WEBROOT/APPHOST'
            Filter            = 'system.webServer/security/requestFiltering'
            CollectionName    = 'verbs'
            ItemName          = 'add'
            ItemKeyName       = 'verb'
            ItemKeyValue      = 'TRACE'
            ItemPropertyName  = 'allowed'
            Ensure            = 'Absent'
        }
    }
}
