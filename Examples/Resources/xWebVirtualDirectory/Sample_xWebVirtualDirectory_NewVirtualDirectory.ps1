<#
    .SYNOPSIS
        Create a new web virtual directory on the Default Web Site
    .DESCRIPTION
        This example shows how to use the xWebVirtualDirectory DSC resource to create a new virtual
        directory on the Default Web Site.
#>
configuration Sample_xWebVirtualDirectory_NewVirtualDirectory
{
    param
    (
        # Target nodes to apply the configuration
        [System.String[]]
        $NodeName = 'localhost',

        # Name of virtual directory to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $VirtualDirectoryName,

        # Physical path of the virtual directory
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PhysicalPath
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
        xWebSite DefaultSite
        {
            Ensure       = 'Present'
            Name         = 'Default Web Site'
            State        = 'Started'
            PhysicalPath = 'C:\inetpub\wwwroot'
            DependsOn    = '[WindowsFeature]IIS'
        }

        # Copy the virtual directory content
        File VirtualDirectoryContent
        {
            Ensure          = 'Present'
            DestinationPath = $PhysicalPath
            Type            = 'Directory'
            DependsOn       = '[WindowsFeature]IIS'
        }

        # Create the new virtual directory
        xWebVirtualDirectory NewVirtualDirectory
        {
            Ensure         = 'Present'
            Website        = "Default Web Site"
            WebApplication = ''
            Name           = $VirtualDirectoryName
            PhysicalPath   = $PhysicalPath
            DependsOn      = '[File]VirtualDirectoryContent'
        }
    }
}
