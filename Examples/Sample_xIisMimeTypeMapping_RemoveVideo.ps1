configuration Sample_RemoveVideoMimeTypeMappings
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost',

        # Name of the website to modify
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $WebSiteName
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

        # Remove a bunch of Video Mime Type mappings
        xIisMimeTypeMapping Mp2 
        {
            Ensure            = 'Absent'
            Extension         = '.mp2'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        xIisMimeTypeMapping Mp4 
        {
            Ensure            = 'Absent'
            Extension         = '.mp4'
            MimeType          = 'video/mp4'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        xIisMimeTypeMapping Mpeg 
        {
            Ensure            = 'Absent'
            Extension         = '.mpeg'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        # we only allow the mpg Video extension on our server
        xIisMimeTypeMapping Mpg 
        {
            Ensure            = 'Present'
            Extension         = '.mpg'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }
    }
}
