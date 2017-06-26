#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                    = 'LocalHost'
            PSDscAllowPlainTextPassword = $true
            Website                     = 'WebsiteForVirtualDirectory'
            WebsitePhysicalPath         = 'C:\inetpub\wwwroot'
            ApplicationPool             = 'DefaultAppPool'
            Port                        = '80'
            WebApplication              = 'WebApplication'
            WebApplicationPhysicalPath  = "C:\inetpub\webapp"
            WebVirtualDirectory         = 'VirtualDirectory'
            PhysicalPath                = 'C:\inetpub\virtualdirectory'
            HostName                    = 'http.website'
        }
    )
}
