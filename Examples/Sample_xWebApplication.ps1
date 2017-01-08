<#
    This shows an example for all possible settings for the xWebApplication resource
#>
configuration MSFT_xWebApplication_Present
{

    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPath
    )

    Import-DscResource -ModuleName xWebAdministration

    node $NodeName
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
