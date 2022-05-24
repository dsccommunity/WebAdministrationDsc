#requires -Version 1

@{
    AllNodes = @(
        @{
            NodeName                    = 'LocalHost'
            PSDscAllowPlainTextPassword = $true
            Website                     = 'Website'
            ApplicationType             = 'WebsiteApplicationType'
            ApplicationPool             = 'DefaultAppPool'
            DefaultPage                 = 'Website.html'
            EnabledProtocols            = 'http'
            SiteId                      = 1234
            PhysicalPath                = 'C:\inetpub\wwwroot'
            PreloadEnabled              = $true
            ServiceAutoStartEnabled     = $true
            ServiceAutoStartProvider    = 'WebsiteServiceAutoStartProvider'
            AuthenticationInfoAnonymous = $true
            AuthenticationInfoBasic     = $false
            AuthenticationInfoDigest    = $false
            AuthenticationInfoWindows   = $true
            HTTPProtocol                = 'http'
            HTTPPort                    = '80'
            HTTP1Hostname               = 'http1.website'
            HTTP2Hostname               = 'http2.website'
            HTTPSProtocol               = 'https'
            HTTPSPort                   = '443'
            HTTPSPort2                  = '8444'
            HTTPSHostname               = 'https.website'
            CertificateStoreName        = 'MY'
            SslFlags                    = '1'
            LogFieldName1               = 'CustomField1'
            SourceName1                 = 'Accept-Encoding'
            SourceType1                 = 'RequestHeader'
            LogFieldName2               = 'CustomField2'
            SourceName2                 = 'Warning'
            SourceType2                 = 'ResponseHeader'
            LogTargetW3C                = 'ETW'
            LogFormat                   = 'W3C'
            Logflags1                   = @('Date','Time','ClientIP','UserName','ServerIP')
            Logflags2                   = @('Date','Time','ClientIP','ServerIP','UserAgent')
        }
    )
}
