<#
    .EXAMPLE
    This example shows how to set a website to require an SSL Cert.
#>

configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [string[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
         xSSLSettings SiteDefaults
         {
            Ensure   = 'Present'
            Name     = 'contoso.com'
            Bindings = @('Ssl', 'SslNegotiateCert', 'SslRequireCert')
         }
    }
}
