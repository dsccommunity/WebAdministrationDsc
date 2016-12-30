#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                    = 'LocalHost'
            PSDscAllowPlainTextPassword = $true
            Website                     = 'WebsiteForVirtualDirectory'
            WebsitePhysicalPath         = 'C:\inetpub\wwwroot'
            ApplicationPool             = 'DefaultAppPool'
            SslFlags                    = '1'
            WebApplication              = 'WebApplication'
            WebApplicationPhysicalPath  = "C:\inetpub\webapp"
            WebVirtualDirectory         = 'VirtualDirectory'
            PhysicalPath                = 'C:\inetpub\virtualdirectory'
            HTTPSProtocol               = 'https'
            HTTPSPort                   = '443'
            HTTPSHostname               = 'https.website'
        }
    )
}
