configuration Sample_SSLSetting_RequireCert
{
    param
    (
        # Target nodes to apply the configuration
        [String[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
         SSLSettings SiteDefaults
         {
            Ensure   = 'Present'
            Name     = 'contoso.com'
            Bindings = @('Ssl', 'SslNegotiateCert', 'SslRequireCert')
         }
    }
}
