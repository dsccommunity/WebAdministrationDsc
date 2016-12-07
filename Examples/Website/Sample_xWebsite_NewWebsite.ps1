<#
    .EXAMPLE
    This example shows how to configure a new website on a node.
#>

configuration NewWebsite
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost',

        # Name of the website to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $WebSiteName,

        # Source Path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $SourcePath,

        # Destination path for Website content
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $DestinationPath
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Stop the default website
        xWebsite DefaultSite 
        {
            Ensure          = 'Present'
            Name            = 'Default Web Site'
            State           = 'Stopped'
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
        }       

        # Create the new Website
        xWebsite NewWebsite
        {
            Ensure          = 'Present'
            Name            = $WebSiteName
            State           = 'Started'
            PhysicalPath    = $DestinationPath
            DependsOn       = '[File]WebContent'
        }
    }
}

