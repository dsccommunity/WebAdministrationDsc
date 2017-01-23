<#
    .SYNOPSIS
        Adds an app setting WebsiteTitle to the configuration file of the website.
    .DESCRIPTION
        This example shows how to use the xWebConfigKeyValue DSC resource for adding an extra key and value to appSettings.
        It will add a key WebSiteTitle with value to the configuration of the site specified.
#>
Configuration Sample_xWebConfigKeyValue_AddAppSetting
{
    param
    (
        # Target nodes to apply the configuration.
        [String[]] $NodeName    = 'localhost',

        # Target website to which the key should be added.
        [String]   $WebsiteName = 'Default Web Site'
    )

    # Import the modules that define custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Adds an extra app setting to the AppSettings section.
        xWebConfigKeyValue DefaultSite 
        {
            Ensure          = 'Present'
            ConfigSection   = 'AppSettings'
            Key             = 'WebsiteTitle'
            Value           = 'xWebAdministration DSC Examples'
            WebsitePath     = 'IIS:\Sites\' + $WebsiteName
        }
    }
}
