configuration Sample_WebSite_WithCustomLogFields_EnsurePresentExplicitly
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
    Import-DscResource -Module WebAdministrationDsc, PSDesiredStateConfiguration

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
        WebSite DefaultSite
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
        WebSite NewWebsite
        {
            Ensure          = 'Present'
            Name            = $WebSiteName
            SiteId          = $SiteId
            State           = 'Started'
            ServerAutoStart = $true
            PhysicalPath    = $DestinationPath
            DependsOn       = '[File]WebContent'
            LogFlags        = @('Date','Time','ClientIP','ServerIP','UserAgent')
            LogFormat       = 'W3C'
            LogCustomFields = @(
                DSC_LogCustomFieldInformation
                {
                    LogFieldName = 'ClientEncoding'
                    SourceName   = 'Accept-Encoding'
                    SourceType   = 'RequestHeader'
                    Ensure       = 'Present'
                }
            )
        }
    }
}
