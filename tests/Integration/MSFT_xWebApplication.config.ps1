#requires -Version 4
configuration DSC_xWebApplication_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {  
        xWebApplication WebApplication
        {
            Website = $Node.Website
            Ensure = 'Present'
            Name = $Node.WebApplication
            PhysicalPath = $Node.PhysicalPath
            WebAppPool = $Node.ApplicationPool
            ApplicationType = $Node.ApplicationType
            AuthenticationInfo = `
                DSC_xWebApplicationAuthenticationInformation
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

configuration DSC_xWebApplication_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName 
    {  
        xWebApplication WebApplication
        {
            Website = $Node.Website
            Ensure = 'Absent'
            Name = $Node.WebApplication
            PhysicalPath = $Node.PhysicalPath
            WebAppPool = $Node.ApplicationPool
        }
    }
}
