configuration Sample_xWebSite_NewWebsite
{
    param
    (
        # Target nodes to apply the configuration
        [String[]]
        $NodeName = 'localhost',

        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,

        # Optional Site Id for the website
        [Parameter()]
        [UInt32]
        $SiteId,

        # Source Path for Website content
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SourcePath,

        # Destination path for Website content
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $DestinationPath
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration, PSDesiredStateConfiguration

    Node $NodeName
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

        # Stop the default website
        xWebSite DefaultSite
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Stopped'
            ServerAutoStart = $false
            PhysicalPath    = 'C:\inetpub\wwwroot'
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Copy the website content
        File WebContent
        {
            Ensure          = 'Present'
            SourcePath      = $SourcePath
            DestinationPath = $DestinationPath
            Recurse         = $true
            Type            = 'Directory'
            DependsOn       = '[WindowsFeature]AspNet45'
        }

        # Create the new Website
        xWebSite NewWebsite
        {
            Ensure          = 'Present'
            Name            = $WebSiteName
            SiteId       = $SiteId
            State           = 'Started'
            ServerAutoStart = $true
            PhysicalPath    = $DestinationPath
            DependsOn       = '[File]WebContent'
        }
    }
}
