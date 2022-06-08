<#
    .SYNOPSIS
        When configuring a new IIS server, several references recommend removing or stopping the default website for security purposes.
        This example sets up your IIS web server by installing IIS Windows Feature.
        After that, it will stop the default website by setting `State = Stopped`.
#>
Configuration Sample_WebSite_StopDefault
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )
    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc
    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name   = "Web-Server"
        }
        # Stop the default website
        WebSite DefaultSite
        {
            Ensure       = "Present"
            Name         = "Default Web Site"
            State        = "Stopped"
            PhysicalPath = "C:\inetpub\wwwroot"
            DependsOn    = "[WindowsFeature]IIS"
        }
    }
}
