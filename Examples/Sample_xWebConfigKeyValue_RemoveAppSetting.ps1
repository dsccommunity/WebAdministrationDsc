<#
    .SYNOPSIS
        Removes an app setting WebsiteTitle from the configuration file of the website if present.
    .DESCRIPTION
        This example shows how to use the xWebConfigKeyValue DSC resource for ensuring a key is not pressent in appSettings.
        It will remove a setting with key WebSiteTitle from the configuration of the site specified.
#>
Configuration Sample_xWebConfigKeyValue_AddAppSetting
{
    param
    (
        # Target nodes to apply the configuration.
        [String[]] $NodeName    = 'localhost',

        # Target website from which the key should be removed.
        [String]   $WebsiteName = 'Default Web Site'
    )

    # Import the modules that define custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Removes an extra app setting from the AppSettings section.
        xWebConfigKeyValue DefaultSite 
        {
            Ensure          = 'Absent'
            ConfigSection   = 'AppSettings'
            Key             = 'WebsiteTitle'
            Value           = 'xWebAdministration DSC Examples'
            WebsitePath     = 'IIS:\Sites\' + $WebsiteName
        }
    }
}
