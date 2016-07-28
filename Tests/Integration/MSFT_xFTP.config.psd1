#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                     = 'LocalHost'
            PSDscAllowPlainTextPassword  = $true
            Name                         = 'ftp'
            State                        = 'Started'
            ApplicationPool              = 'DefaultAppPool'
            PhysicalPath                 = 'C:\inetpub\ftproot'
            AuthenticationInfoAnonymous  = $true
            AuthenticationInfoBasic      = $false
            AuthorizationInfoAccessType  = 'Allow'
            AuthorizationInfoUsers       = 'User1'
            AuthorizationInfoRoles       = 'Group1'
            AuthorizationInfoPermissions = 'Read'
            BindingInfoProtocol          = 'ftp'
            BindingInfoPort              = '21'
            BindingInfoHostName          = 'ftp.server'
            SslInfoControlChannelPolicy  = 'SslAllow'
            SslInfoDataChannelPolicy     = 'SslAllow'
            SslInfoRequireSsl128         = $true
            SslInfoCertificateStoreName  = 'My'
            LogPath                      = 'C:\inetpub\logs'
            LogFlags                     = @('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem')
            LogPeriod                    = 'Hourly'
            LoglocalTimeRollover         = $true
            DirectoryBrowseFlags         = 'StyleUnix'
            UserIsolation                = 'IsolateAllDirectories'
        }
    )
}
