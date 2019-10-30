<#
    .DESCRIPTION
        While setting up IIS and stopping the default website is interesting, it isn�t quite useful yet.
        After all, people typically use IIS to set up websites of their own with custom protocol and bindings.
        Fortunately, using DSC, adding another website is as simple as using the File and xWebSite resources to
        copy the website content and configure the website.
#>
Configuration Sample_xWebSite_NewWebsite_UsingCertificateThumbprint
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]
        $NodeName = 'localhost',
        # Name of the website to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $WebSiteName,
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
    Import-DscResource -Module xWebAdministration
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

        # Create the new Website with HTTPS
        xWebSite NewWebsite
        {
            Ensure          = 'Present'
            Name            = $WebSiteName
            State           = 'Started'
            PhysicalPath    = $DestinationPath
            BindingInfo     = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = 'HTTPS'
                    Port                  = 8443
                    CertificateThumbprint = '71AD93562316F21F74606F1096B85D66289ED60F'
                    CertificateStoreName  = 'WebHosting'
                }
                MSFT_xWebBindingInformation
                {
                    Protocol              = 'HTTPS'
                    Port                  = 8444
                    CertificateThumbprint = 'DEDDD963B28095837F558FE14DA1FDEFB7FA9DA7'
                    CertificateStoreName  = 'MY'
                }
            )
            DependsOn       = '[File]WebContent'
        }
    }
}
