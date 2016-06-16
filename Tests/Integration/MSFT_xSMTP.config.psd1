#requires -Version 1
@{
    AllNodes = @(
        @{
                Name                             = '1'
                AuthFlags                        = '2'
                BadMailDirectory                 = '{C:\SMTP\Badmail} '
                ConnectionTimeout                = '1200'
                EnableReverseDnsLookup           = $true
                FullyQualifiedDomainName         = 'domain.com'
                HopCount                         = '30'
                LogFileDirectory                 = 'C:\SMTP\LogFiles'
                LogFilePeriod                    = '2'
                LogFileTruncateSize              = '40960000'
                LogType                          = '1'
                MasqueradeDomain                 = 'Mock@domain.com'
                MaxBatchedMessages               = '10'
                MaxConnections                   = '1000000000'
                MaxMessageSize                   = '1024152'
                MaxOutConnections                = '2000'
                MaxOutConnectionsPerDomain       = '200'
                MaxRecipients                    = '200'
                MaxSessionSize                   = '20965760'
                RelayForAuth                     = '2'
                RemoteSmtpPort                   = '26'
                RemoteTimeout                    = '1200'
                SaslLogonDomain                  = 'Mock@domain.com'
                SendNdrTo                        = 'ndr@domain.com'
                ServerBindings                   = ':25:, :26:'
                SmartHost                        = 'smarthost.domain.com'
                SmartHostType                    = '1'
                SmtpInboundCommandSupportOptions = '1234567'
                SmtpLocalDelayExpireMinutes      = '1440'
                SmtpLocalNDRExpireMinutes        = '7220'
                SmtpRemoteDelayExpireMinutes     = '1440'
                SmtpRemoteNDRExpireMinutes       = '7220'
                SmtpRemoteProgressiveRetry       = '30,60,120,480'
        }
    )
}
