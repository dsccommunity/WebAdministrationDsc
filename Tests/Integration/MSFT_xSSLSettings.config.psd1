#requires -Version 1

# Suppressing this rule because this isn't a module manifest
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSMissingModuleManifestField', '')]
param ()

@{
    AllNodes = @(
        @{
            NodeName                    = 'LocalHost'
            PSDscAllowPlainTextPassword = $true
            Website                     = 'WebsiteForSSLSettings'
            ApplicationPool             = 'DefaultAppPool'
            PhysicalPath                = 'C:\inetpub\wwwroot'
            HTTPSProtocol               = 'https'
            HTTPSPort                   = '443'
            HTTPSHostname               = 'https.website'
            CertificateStoreName        = 'MY'
            SslFlags                    = '1'
            Bindings                    = @('Ssl')
        }
    )
}
