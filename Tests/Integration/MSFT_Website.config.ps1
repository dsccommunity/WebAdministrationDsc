#requires -Version 4
configuration MSFT_Website_Present_Started
{
    param(
        
        [Parameter(Mandatory = $true)]
        [String]$CertificateThumbprint
    
    )

    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {  
        Website Website
        {
            Name = $Node.Website
            Ensure = 'Present'
            ApplicationType = $Node.ApplicationType
            ApplicationPool = $Node.ApplicationPool
            AuthenticationInfo = `
                MSFT_WebAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            BindingInfo = @(MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP1Hostname
                }
                MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP2Hostname
                }
                MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
                })
            DefaultPage = $Node.DefaultPage
            EnabledProtocols = $Node.EnabledProtocols
            PhysicalPath = $Node.PhysicalPath
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            State = 'Started'
        }
    }
}

configuration MSFT_Website_Present_Stopped
{
    param(
        
        [Parameter(Mandatory = $true)]
        [String]$CertificateThumbprint
    
    )

    Import-DscResource -ModuleName WebAdministration

    Node $AllNodes.NodeName 
    {  
        Website Website
        {
            Name = $Node.Website
            Ensure = 'Present'
            ApplicationType = $Node.ApplicationType
            ApplicationPool = $Node.ApplicationPool
            AuthenticationInfo = `
                MSFT_WebAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                    Digest    = $Node.AuthenticationInfoDigest
                    Windows   = $Node.AuthenticationInfoWindows
                }
            BindingInfo = @(
                MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP1Hostname
                }
                MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPProtocol
                    Port                  = $Node.HTTPPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTP2Hostname
                }
                MSFT_WebBindingInformation
                {
                    Protocol              = $Node.HTTPSProtocol
                    Port                  = $Node.HTTPSPort
                    IPAddress             = '*'
                    Hostname              = $Node.HTTPSHostname
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.CertificateStoreName
                    SslFlags              = $Node.SslFlags
            })
            DefaultPage = $Node.DefaultPage
            EnabledProtocols = $Node.EnabledProtocols
            PhysicalPath = $Node.PhysicalPath
            PreloadEnabled = $Node.PreloadEnabled
            ServiceAutoStartEnabled = $Node.ServiceAutoStartEnabled
            ServiceAutoStartProvider = $Node.ServiceAutoStartProvider
            State = 'Stopped'
        }
    }
}

configuration MSFT_Website_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName 
    {  
        Website Website
        {
            Name = $Node.Website
            Ensure = 'Absent'
        }
    }
}
