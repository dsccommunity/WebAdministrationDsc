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
            HostName                    = 'http.website'
            WebApplication              = 'WebApplication'
            WebApplicationPhysicalPath  = "C:\inetpub\webapp"
            FolderName                  = 'testFolder'
            WebVirtualDirectory         = 'VirtualDirectory'
            PhysicalPath1               = 'C:\inetpub\virtualdirectory1'
            PhysicalPath2               = 'C:\inetpub\virtualdirectory2'
            PhysicalPath3               = 'C:\inetpub\virtualdirectory3'
            PhysicalPath4               = 'C:\inetpub\virtualdirectory4'
            PhysicalPathUserName1       = 'mockUser'
            PhysicalPathPassword1       = 'v3r1fY_P@$$w0rd'
            PhysicalPathUserName2       = 'diffUser'
            PhysicalPathPassword2       = 't35t_P@$$w0rd'
        }
    )
}
