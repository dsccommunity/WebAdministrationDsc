<#
    .EXAMPLE
    This example shows how to create a new site default.
    Specifically showing how to set the log format for the site.
#>

configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
         xWebSiteDefaults SiteDefaults
         {
            ApplyTo = 'Machine'
            LogFormat = 'IIS'
            AllowSubDirConfig = 'true'
         }
    }
}
