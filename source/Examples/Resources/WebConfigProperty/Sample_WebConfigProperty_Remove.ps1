<#
.SYNOPSIS
    Removes configuration of directory browsing in the default website.

.DESCRIPTION
    This example shows how to use the WebConfigProperty DSC resource for removing a configuration property.
    It will remove the system.webServer/directoryBrowse enabled attribute (if present) in the Web.config file for the default website.
#>
Configuration Sample_WebConfigProperty_Remove
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
        WebConfigProperty "$($NodeName) - Ensure 'directory browsing' is set to disabled - Remove"
        {
            WebsitePath  = 'IIS:\Sites\Default Web Site'
            Filter       = 'system.webServer/directoryBrowse'
            PropertyName = 'enabled'
            Ensure       = 'Absent'
        }
    }
}
