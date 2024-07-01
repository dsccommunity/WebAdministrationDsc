<#
    .SYNOPSIS
        Create a new web virtual directory on the Default Web Site
    .DESCRIPTION
        This example shows how to use the WebVirtualDirectory DSC resource to create a new virtual
        directory on the Default Web Site with a UNC path that requires credentials.
#>
configuration Sample_WebVirtualDirectory_NewVirtualDirectory_WithUncPath
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
        $PhysicalPath,

        # Credential to use for the virtual directory
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module WebAdministrationDsc

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure = 'Present'
            Name   = 'Web-Server'
        }

        # Start the default website
        WebSite DefaultSite
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
        WebVirtualDirectory NewVirtualDirectory
        {
            Ensure         = 'Present'
            Website        = "Default Web Site"
            WebApplication = ''
            Name           = $VirtualDirectoryName
            PhysicalPath   = $PhysicalPath
            DependsOn      = '[File]VirtualDirectoryContent'
            Credential     = $Credential
        }
    }
}
