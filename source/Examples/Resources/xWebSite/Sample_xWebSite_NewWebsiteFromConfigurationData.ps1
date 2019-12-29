Configuration Sample_xWebSite_NewWebsiteFromConfigurationData
{
    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    # Dynamically find the applicable nodes from configuration data
    Node $AllNodes.where{ $_.Role -eq 'Web' }.NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = 'Present'
            Name            = 'Web-Server'
        }

        # Install the ASP .NET 4.5 role
        WindowsFeature AspNet45
        {
            Ensure          = 'Present'
            Name            = 'Web-Asp-Net45'
        }

        # Stop an existing website (set up in Sample_xWebSite_Default)
        xWebSite DefaultSite
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Stopped'
            ServerAutoStart = $false
            PhysicalPath    = $Node.DefaultWebSitePath
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = 'Present'
            SourcePath      = $Node.SourcePath
            DestinationPath = $Node.DestinationPath
            Recurse         = $true
            Type            = 'Directory'
            DependsOn       = '[WindowsFeature]AspNet45'
        }

        # Create a new website
        xWebSite BakeryWebSite
        {
            Ensure          = 'Present'
            Name            = $Node.WebsiteName
            State           = 'Started'
            ServerAutoStart = $true
            PhysicalPath    = $Node.DestinationPath
            DependsOn       = '[File]WebContent'
        }
    }
}

# Hashtable to define the environmental data
$ConfigurationData = @{
    # Node specific data
    AllNodes = @(

        # All the WebServers have the following identical information
        @{
            NodeName           = '*'
            WebsiteName        = 'FourthCoffee'
            SourcePath         = 'C:\BakeryWebsite\'
            DestinationPath    = 'C:\inetpub\FourthCoffee'
            DefaultWebSitePath = 'C:\inetpub\wwwroot'
        },

        @{
            NodeName = 'WebServer1.fourthcoffee.com'
            Role     = 'Web'
        },

        @{
            NodeName = 'WebServer2.fourthcoffee.com'
            Role     = 'Web'
        }
    );
}
