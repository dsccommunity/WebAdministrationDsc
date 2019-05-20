#requires -Version 1
@{
    AllNodes = @(
        @{
            NodeName                      = 'LocalHost'
            PSDscAllowPlainTextPassword   = $true
            Name                          = 'ftp'
            State                         = 'Started'
            ApplicationPool               = 'DefaultAppPool'
            PhysicalPath                  = 'C:\inetpub\ftproot'
            PhysicalPathUserName          = 'mockFtpUser'
            PhysicalPathPassword          = 'P@$$w0rdP@55wOrd'
            AuthenticationInfoAnonymous   = $false
            AuthenticationInfoBasic       = $true
            AuthorizationInfoAccessType1  = 'Allow'
            AuthorizationInfoAccessType2  = 'Deny'
            AuthorizationInfoUsers1       = 'User1'
            AuthorizationInfoUsers2       = '*'
            AuthorizationInfoUsers3       = '?'
            AuthorizationInfoRoles        = 'Group1'
            AuthorizationInfoPermissions1 = 'Read'
            AuthorizationInfoPermissions2 = 'Write'
            AuthorizationInfoPermissions3 = 'Read,Write'
            BindingInfoProtocol           = 'ftp'
            BindingInfoPort               = '21'
            BindingInfoHostName           = 'ftp.server'
            SslInfoControlChannelPolicy   = 'SslAllow'
            SslInfoDataChannelPolicy      = 'SslAllow'
            SslInfoRequireSsl128          = $true
            SslInfoCertificateStoreName   = 'My'
            FirewallIPaddress             = '10.0.0.10'
            StartingDataChannelPort       = 10500
            EndingDataChannelPort         = 10550
            GreetingMessage               = 'Greetings, %UserName%!'
            ExitMessage                   = 'Bye, %UserName%!'
            BannerMessage                 = "%UserName%, you've been watched.."
            MaxClientsMessage             = 'Sorry, %UserName%, try to connect again in an hour.'
            SuppressDefaultBanner         = $false
            AllowLocalDetailedErrors      = $true
            ExpandVariablesInMessages     = $true
            LogPath                       = 'C:\inetpub\logs'
            LogFlags                      = @('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem')
            LogPeriod                     = 'Hourly'
            LoglocalTimeRollover          = $true
            DirectoryBrowseFlags          = @('StyleUnix','LongDate','DisplayAvailableBytes','DisplayVirtualDirectories')
            UserIsolation                 = 'IsolateAllDirectories'
        }
    )
}
