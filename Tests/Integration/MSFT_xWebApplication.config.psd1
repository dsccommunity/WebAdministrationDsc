#requires -Version 1

# Suppressing this rule because this isn't a module manifest
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSMissingModuleManifestField', '')]
param ()

@{
    AllNodes = @(
        @{
            NodeName                    = 'LocalHost'
            PSDscAllowPlainTextPassword = $true
            Website                     = 'WebsiteForWebApplication'
            WebApplication              = 'WebApplication'
            ApplicationType             = 'WebsiteApplicationType'
            ApplicationPool             = 'DefaultAppPool'
            PhysicalPath                = 'C:\inetpub\wwwroot'
            PreloadEnabled              = $true
            ServiceAutoStartEnabled     = $true
            ServiceAutoStartProvider    = 'WebsiteServiceAutoStartProvider'
            AuthenticationInfoAnonymous = $true
            AuthenticationInfoBasic     = $false
            AuthenticationInfoDigest    = $false
            AuthenticationInfoWindows   = $true
            HTTPSProtocol               = 'https'
            HTTPSPort                   = '443'
            HTTPSHostname               = 'https.website'
            CertificateStoreName        = 'MY'
            SslFlags                    = '1'
            WebApplicationSslFlags      = @('Ssl')
        }
    )
}
