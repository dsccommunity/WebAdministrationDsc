<#
    .SYNOPSIS
        Create a new web virtual directories on the Default Web Site

    .DESCRIPTION
        This example shows how to use the WebVirtualDirectory DSC resource to create a new virtual
        directories on the Default Web Site.
#>
configuration Sample_WebVirtualDirectory_NewVirtualDirectory
{
    param
    (
        # Target nodes to apply the configuration
        [System.String[]]
        $NodeName = 'localhost',

        # Name of virtual directory to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VirtualDirectoryName,

        # Physical path of the virtual directory
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath,

        # Another physical path of the virtual directory
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath2 = 'C:\inetpub\wwwroot\virtualdirectory2',

        [Parameter()]
        [System.String]
        $FolderName = 'AnotherFolder'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Start the default website
        xWebsite DefaultSite
        {
            Ensure       = 'Present'
            Name         = 'Default Web Site'
            State        = 'Started'
            PhysicalPath = 'C:\inetpub\wwwroot'
            DependsOn    = '[WindowsFeature]IIS'
        }

        # Create folder at site root
        File SiteFolder
        {
            Ensure          = 'Present'
            DestinationPath = "C:\inetpub\wwwroot\$FolderName"
            Type            = 'Directory'
        }

        # Create folder for the virtual directory content
        File VirtualDirectoryContent
        {
            Ensure          = 'Present'
            DestinationPath = $PhysicalPath
            Type            = 'Directory'
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Create another folder for the virtual directory content
        File VirtualDirectoryContent2
        {
            Ensure          = 'Present'
            DestinationPath = $PhysicalPath2
            Type            = 'Directory'
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Create the new virtual directory at site root
        WebVirtualDirectory VD_Site_Root
        {
            Ensure       = 'Present'
            Site         = 'Default Web Site'
            Application  = ''
            Name         = $VirtualDirectoryName
            PhysicalPath = $PhysicalPath
            DependsOn    = '[File]VirtualDirectoryContent'
        }

        # Create the new virtual directory at different folder in site
        WebVirtualDirectory VD_Site
        {
            Ensure       = 'Present'
            Site         = 'Default Web Site'
            Application  = ''
            Name         = "$FolderName/$VirtualDirectoryName"
            PhysicalPath = $PhysicalPath2
            DependsOn    = '[File]SiteFolder','[File]VirtualDirectoryContent2'
        }
    }
}
