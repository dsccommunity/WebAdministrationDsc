<#
    .SYNOPSIS
        Remove existing virtual directories on the Default Web Site

    .DESCRIPTION
        This example shows how to use the WebVirtualDirectory DSC resource to remove existing virtual
        directories on the Default Web Site.
#>
configuration Sample_WebVirtualDirectory_RemoveVirtualDirectory
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

        [Parameter()]
        [System.String]
        $FolderName = 'AnotherFolder'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Remove virtual directory at site root
        WebVirtualDirectory VD_Site_Root
        {
            Ensure      = 'Absent'
            Site        = 'Default Web Site'
            Application = ''
            Name        = $VirtualDirectoryName
        }

        # Remove virtual directory at different folder in site
        WebVirtualDirectory VD_Site
        {
            Ensure      = 'Present'
            Site        = 'Default Web Site'
            Application = ''
            Name        = "$FolderName/$VirtualDirectoryName"
        }
    }
}
