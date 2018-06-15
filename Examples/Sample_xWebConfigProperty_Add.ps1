<#
.SYNOPSIS
    Disables directory browsing in the default website.

.DESCRIPTION
    This example shows how to use the xWebConfigProperty DSC resource for setting a configuration property.
    It will set the value of the system.webServer/directoryBrowse enabled attribute to false in the Web.config file for the default website.
#>
Configuration Sample_xWebConfigProperty_Add
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
        xWebConfigProperty "$($NodeName) - Ensure 'directory browsing' is set to disabled - Add"
        {
            WebsitePath = 'IIS:\Sites\Default Web Site'
            Filter = 'system.webServer/directoryBrowse'
            PropertyName = 'enabled'
            Value = 'false'
            Ensure = 'Present'
        }
    }
}
