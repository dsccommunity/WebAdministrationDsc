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
            Ensure = 'Present'
            Name = $Node.Name
            ApplicationPool = $Node.ApplicationPool
            PhysicalPath = $Node.PhysicalPath
            State = $Node.State
            AuthorizationInfo = @(
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType = $Node.AuthorizationInfoAccessType
                    Users = $Node.AuthorizationInfoUsers
                    Roles = ''
                    Permissions = $Node.AuthorizationInfoPermissions
                };
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType = $Node.AuthorizationInfoAccessType
                    Users = ''
                    Roles = $Node.AuthorizationInfoRoles
                    Permissions = $Node.AuthorizationInfoPermissions
                })
            BindingInfo = `
                MSFT_xFTPBindingInformation
                {
                    Protocol = $Node.BindingInfoProtocol
                    Port = $Node.BindingInfoPort
                    HostName = $Node.BindingInfoHostName
                }
            SslInfo = `
                MSFT_xFTPSslInformation
                {
                    ControlChannelPolicy = $Node.SslInfoControlChannelPolicy
                    DataChannelPolicy = $Node.SslInfoDataChannelPolicy
                    RequireSsl128 = $Node.SslInfoRequireSsl128
                    CertificateHash = $CertificateThumbprint
                    CertificateStoreName = $Node.SslInfoCertificateStoreName
                }
            LogPath = $Node.LogPath
            LogFlags = $Node.LogFlags
            LogPeriod = $Node.LogPeriod
            LoglocalTimeRollover = $Node.LoglocalTimeRollover
            DirectoryBrowseFlags = $Node.DirectoryBrowseFlags
            UserIsolation = $Node.UserIsolation
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
