configuration MSFT_xWebApplication_Present
{

    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$PhysicalPath
    )

    Import-DscResource -ModuleName xWebAdministration

    Node $Node
    {  
        xWebApplication WebApplication
        {
            Website = 'Website'
            Ensure = 'Present'
            Name = 'WebApplication'
            PhysicalPath = $PhysicalPath
            WebAppPool = 'DefaultAppPool'
            ApplicationType = 'ApplicationType'
            AuthenticationInfo = `
            MSFT_xWebApplicationAuthenticationInformation
            {
                Anonymous = $true
                Basic     = $false
                Digest    = $false
                Windows   = $false
            }
            PreloadEnabled = $true
            ServiceAutoStartEnabled = $true
            ServiceAutoStartProvider = 'ServiceAutoStartProvider'
            SslFlags = @('Ssl')
            EnabledProtocols = @('http','net.tcp')
        }
    }
}