#requires -Version 4
configuration DSC_WebApplication_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        WebApplication WebApplication
        {
            Website = $Node.Website
            Ensure = 'Present'
            Name = $Node.WebApplication
            PhysicalPath = $Node.PhysicalPath
            WebAppPool = $Node.ApplicationPool
            ApplicationType = $Node.ApplicationType
            AuthenticationInfo = `
                DSC_WebApplicationAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            SslFlags = $Node.WebApplicationSslFlags
            EnabledProtocols = $Node.EnabledProtocols
        }
    }
}

configuration DSC_WebApplication_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        WebApplication WebApplication
        {
            Website = $Node.Website
            Ensure = 'Absent'
            Name = $Node.WebApplication
            PhysicalPath = $Node.PhysicalPath
            WebAppPool = $Node.ApplicationPool
        }
    }
}
