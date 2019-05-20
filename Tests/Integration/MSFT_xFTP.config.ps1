#requires -Version 4

configuration MSFT_xFTP_Present
{
    param(

        [Parameter(Mandatory = $true)]
        [String]$CertificateThumbprint

    )

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xFTP FTP
        {
            Ensure                 = 'Present'
            Name                   = $Node.Name
            ApplicationPool        = $Node.ApplicationPool
            PhysicalPath           = $Node.PhysicalPath
             PhysicalPathCredential = New-Object System.Management.Automation.PSCredential ($Node.PhysicalPathUserName, `
                                         (ConvertTo-SecureString -String $Node.PhysicalPathPassword -AsPlainText -Force))
            State                  = $Node.State
            AuthenticationInfo     = `
                MSFT_xFTPAuthenticationInformation
                {
                    Anonymous = $Node.AuthenticationInfoAnonymous
                    Basic     = $Node.AuthenticationInfoBasic
                }
            AuthorizationInfo  = @(
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType  = $Node.AuthorizationInfoAccessType1
                    Users       = $Node.AuthorizationInfoUsers1
                    Roles       = ''
                    Permissions = $Node.AuthorizationInfoPermissions1
                };
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType  = $Node.AuthorizationInfoAccessType1
                    Users       = $Node.AuthorizationInfoUsers2
                    Roles       = ''
                    Permissions = $Node.AuthorizationInfoPermissions3
                };
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType  = $Node.AuthorizationInfoAccessType2
                    Users       = $Node.AuthorizationInfoUsers3
                    Roles       = ''
                    Permissions = $Node.AuthorizationInfoPermissions1
                };
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType  = $Node.AuthorizationInfoAccessType1
                    Users       = ''
                    Roles       = $Node.AuthorizationInfoRoles
                    Permissions = $Node.AuthorizationInfoPermissions1
                };
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType  = $Node.AuthorizationInfoAccessType2
                    Users       = ''
                    Roles       = $Node.AuthorizationInfoRoles
                    Permissions = $Node.AuthorizationInfoPermissions2
                })
            BindingInfo = `
                MSFT_xFTPBindingInformation
                {
                    Protocol = $Node.BindingInfoProtocol
                    Port     = $Node.BindingInfoPort
                    HostName = $Node.BindingInfoHostName
                }
            SslInfo = `
                MSFT_xFTPSslInformation
                {
                    ControlChannelPolicy  = $Node.SslInfoControlChannelPolicy
                    DataChannelPolicy     = $Node.SslInfoDataChannelPolicy
                    RequireSsl128         = $Node.SslInfoRequireSsl128
                    CertificateThumbprint = $CertificateThumbprint
                    CertificateStoreName  = $Node.SslInfoCertificateStoreName
                }
            FirewallIPaddress         = $Node.FirewallIPaddress
            StartingDataChannelPort   = $Node.StartingDataChannelPort
            EndingDataChannelPort     = $Node.EndingDataChannelPort
            GreetingMessage           = $Node.GreetingMessage
            ExitMessage               = $Node.ExitMessage
            BannerMessage             = $Node.BannerMessage
            MaxClientsMessage         = $Node.MaxClientsMessage
            SuppressDefaultBanner     = $Node.SuppressDefaultBanner
            AllowLocalDetailedErrors  = $Node.AllowLocalDetailedErrors
            ExpandVariablesInMessages = $Node.ExpandVariablesInMessages
            LogPath                   = $Node.LogPath
            LogFlags                  = $Node.LogFlags
            LogPeriod                 = $Node.LogPeriod
            LoglocalTimeRollover      = $Node.LoglocalTimeRollover
            DirectoryBrowseFlags      = $Node.DirectoryBrowseFlags
            UserIsolation             = $Node.UserIsolation
        }
    }
}

configuration MSFT_xFTP_Absent
{

    Import-DscResource -ModuleName xWebAdministration

    Node $AllNodes.NodeName
    {
        xFTP FTP
        {
            Ensure = 'Absent'
            Name = $Node.Name

        }
    }
}
