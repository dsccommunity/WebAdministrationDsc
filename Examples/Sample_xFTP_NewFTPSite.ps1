configuration Sample_xFTP_NewFTPsite
{
    param(
        
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost',

        # Name of the website to create
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $FTPSitePath,

        [Parameter(Mandatory)]
        [String] $CertificateThumbprint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $FTPLogPath
    
    )

    Import-DscResource -ModuleName xWebAdministration

    Node $NodeName
    {  
        xFTP NewFTPSite
        {
            Ensure = 'Present'
            Name = $Name
            ApplicationPool = 'DefaultAppPool'
            PhysicalPath = $FTPSitePath
            State = 'Started'
            AuthorizationInfo = @(
                MSFT_xFTPAuthorizationInformation
                {
                    AccessType = 'Allow'
                    Users = 'User1'
                    Roles = ''
                    Permissions = 'Read'
                })
            BindingInfo = `
                MSFT_xFTPBindingInformation
                {
                    Protocol = 'ftp'
                    Port = '21'
                    HostName = 'ftp.somesite.com'
                }
            SslInfo = `
                MSFT_xFTPSslInformation
                {
                    ControlChannelPolicy = 'SslAllow'
                    DataChannelPolicy = 'SslAllow'
                    RequireSsl128 = $true
                    CertificateHash = $CertificateThumbprint
                    CertificateStoreName = 'My'
                }
            LogPath = $FTPLogPath
            LogFlags = @('Date','Time','ClientIP','UserName','ServerIP','Method','UriStem')
            LogPeriod = 'Hourly'
            LoglocalTimeRollover = $true
            DirectoryBrowseFlags = 'StyleUnix'
            UserIsolation = 'IsolateAllDirectories'
        }
    }
}