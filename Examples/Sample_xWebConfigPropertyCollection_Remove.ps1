<#
.SYNOPSIS
    Removes disabling the HTTP TRACE method at the server level.

.DESCRIPTION
    This example shows how to use the xWebConfigPropertyCollection DSC resource for removing a configuration element.
    It will remove the "add" element from the system.webServer/security/requestFiltering/verbs collection (if present) for disabling the HTTP TRACE verb.
#>
Configuration Sample_xWebConfigPropertyCollection_Remove
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
        xWebConfigPropertyCollection "$($NodeName) - Remove disabling HTTP TRACE method"
        {
            WebsitePath = 'MACHINE/WEBROOT/APPHOST'
            Filter = 'system.webServer/security/requestFiltering'
            CollectionName = 'verbs'
            ItemName = 'add'
            ItemKeyName = 'verb'
            ItemKeyValue = 'TRACE'
            Ensure = 'Absent'
        }
    }
}
