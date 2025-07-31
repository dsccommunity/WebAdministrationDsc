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
            Credential                  = @{
                UserName = 'CONTOSO\JDoe'
                Password = '5t6y7u8i'
            }
            HostName                    = 'http.website'
        }
    )
}
