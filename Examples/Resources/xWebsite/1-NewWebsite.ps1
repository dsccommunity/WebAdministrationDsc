<#
    .EXAMPLE
    This example shows how to configure a new website on a node.
#>

configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )

    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xWebsite NewWebsite
        {
            Ensure          = 'Present'
            Name            = 'contoso.com'
            State           = 'Started'
            PhysicalPath    = 'C:\webroot'
        }
    }
}
