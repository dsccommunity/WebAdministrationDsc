configuration Sample_IisMimeTypeMapping_RemoveVideo
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
    Import-DscResource -Module WebAdministrationDsc, PSDesiredStateConfiguration

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Remove a bunch of Video Mime Type mappings
        IisMimeTypeMapping Mp2
        {
            Ensure            = 'Absent'
            Extension         = '.mp2'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        IisMimeTypeMapping Mp4
        {
            Ensure            = 'Absent'
            Extension         = '.mp4'
            MimeType          = 'video/mp4'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        IisMimeTypeMapping Mpeg
        {
            Ensure            = 'Absent'
            Extension         = '.mpeg'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        # we only allow the mpg and mpe Video extensions on our server
        IisMimeTypeMapping Mpg
        {
            Ensure            = 'Present'
            Extension         = '.mpg'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }

        IisMimeTypeMapping Mpg
        {
            # Ensure defaults to 'Present'
            Extension         = '.mpe'
            MimeType          = 'video/mpeg'
            ConfigurationPath = "IIS:\sites\$WebSiteName"
            DependsOn         = '[WindowsFeature]IIS'
        }
    }
}
