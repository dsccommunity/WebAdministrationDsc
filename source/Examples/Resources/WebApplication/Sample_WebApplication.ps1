<#
    This shows an example for all possible settings for the WebApplication resource
#>
configuration Sample_WebApplication
{

    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $PhysicalPath
    )

    Import-DscResource -ModuleName WebAdministrationDsc

    node $NodeName
    {
        WebApplication WebApplication
        {
            Website                  = 'Website'
            Ensure                   = 'Present'
            Name                     = 'WebApplication'
            PhysicalPath             = $PhysicalPath
            WebAppPool               = 'DefaultAppPool'
            ApplicationType          = 'ApplicationType'
            AuthenticationInfo       = `
                MSFT_WebApplicationAuthenticationInformation
            {
                Anonymous = $true
                Basic     = $false
                Digest    = $false
                Windows   = $false
            }
            PreloadEnabled           = $true
            ServiceAutoStartEnabled  = $true
            ServiceAutoStartProvider = 'ServiceAutoStartProvider'
            SslFlags                 = @('Ssl')
            EnabledProtocols         = @('http', 'net.tcp')
        }
    }
}
