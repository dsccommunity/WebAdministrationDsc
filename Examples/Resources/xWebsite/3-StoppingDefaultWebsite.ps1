<#
    .EXAMPLE
    When configuring a new IIS server, several references recommend removing or
    stopping the default website for security purposes.
    This example sets up your IIS web server by installing IIS Windows Feature.
    After that, it will stop the default website by setting `State = Stopped`.
#>
Configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost'
    )

    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Stop the default website
        xWebsite DefaultSite
        {
            Ensure          = "Present"
            Name            = "Default Web Site"
            State           = "Stopped"
            PhysicalPath    = "C:\inetpub\wwwroot"
        }
    }
}
