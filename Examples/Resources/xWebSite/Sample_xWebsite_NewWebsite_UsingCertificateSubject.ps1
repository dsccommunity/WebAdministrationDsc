<#
    .DESCRIPTION
        When specifying a HTTPS web binding you can also specify a certifcate subject, for cases where the certificate
        is being generated by the same configuration using something like xCertReq.
#>
Configuration Sample_xWebsite_NewWebsite
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
            DependsOn       = '[WindowsFeature]AspNet45'
        }

        # Create the new Website with HTTPS
        xWebsite NewWebsite
        {
            Ensure          = 'Present'
            Name            = $WebSiteName
            State           = 'Started'
            PhysicalPath    = $DestinationPath
            BindingInfo     = @(
                MSFT_xWebBindingInformation
                {
                    Protocol              = 'HTTPS'
                    Port                  = 8444
                    CertificateSubject    = 'CN=CertificateSubject'
                    CertificateStoreName  = 'MY'
                }
            )
            DependsOn       = '[File]WebContent'
        }
    }
}