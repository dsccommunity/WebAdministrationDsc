#requires -Version 4
configuration MSFT_xSMTP_Present
{
    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {  
        xSMTP SMTP
        {
            Name = $Node.Name
            AuthFlags = $Node.AuthFlags
            BadMailDirectory = $Node.BadMailDirectory
            ConnectionTimeout = $Node.ConnectionTimeout
            EnableReverseDnsLookup = $Node.EnableReverseDnsLookup
            FullyQualifiedDomainName = $Node.FullyQualifiedDomainName
            HopCount = $Node.HopCount
            LogFileDirectory = $Node.LogFileDirectory
            LogFilePeriod = $Node.LogFilePeriod
            LogFileTruncateSize = $Node.LogFileTruncateSize
            LogType = $Node.LogType
            MasqueradeDomain = $Node.MasqueradeDomain
            MaxBatchedMessages = $Node.MaxBatchedMessages
            MaxConnections = $Node.MaxConnections
            MaxMessageSize = $Node.MaxMessageSize
            MaxOutConnections = $Node.MaxOutConnections
            MaxOutConnectionsPerDomain = $Node.MaxOutConnectionsPerDomain
            MaxRecipients = $Node.MaxRecipients
            MaxSessionSize = $Node.MaxSessionSize
            RelayForAuth = $Node.RelayForAuth
            RemoteSmtpPort = $Node.RemoteSmtpPort
            RemoteTimeout = $Node.RemoteTimeout
            SaslLogonDomain = $Node.SaslLogonDomain
            SendNdrTo = $Node.SendNdrTo
            ServerBindings = $Node.ServerBindings
            SmartHost = $Node.SmartHost
            SmartHostType = $Node.SmartHostType
            SmtpInboundCommandSupportOptions = $Node.SmtpInboundCommandSupportOptions
            SmtpLocalDelayExpireMinutes = $Node.SmtpLocalDelayExpireMinutes
            SmtpLocalNDRExpireMinutes = $Node.SmtpLocalNDRExpireMinutes
            SmtpRemoteDelayExpireMinutes = $Node.SmtpRemoteDelayExpireMinutes
            SmtpRemoteNDRExpireMinutes = $Node.SmtpRemoteNDRExpireMinutes
            SmtpRemoteProgressiveRetry = $Node.SmtpRemoteProgressiveRetry
        }
    }
}
