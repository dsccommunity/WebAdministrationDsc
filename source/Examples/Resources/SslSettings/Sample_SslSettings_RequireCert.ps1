configuration Sample_SslSettings_RequireCert
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc

    Node $NodeName
    {
        SslSettings SiteDefaults
        {
            Ensure   = 'Present'
            Name     = 'contoso.com'
            Bindings = @('Ssl', 'SslNegotiateCert', 'SslRequireCert')
        }
    }
}
