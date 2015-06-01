configuration Sample_IISFeatureDelegation
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module cWebAdministration

    Node $NodeName
    {
        # Install the IIS role
        WindowsFeature IIS
        {
            Ensure          = "Present"
            Name            = "Web-Server"
        }

        # Allow Write access to some section that normally don't have it.
        cFeatureDelegation serverRuntime 
        {
            SectionName      = "serverRuntime"
            OverrideMode   = "Allow"
        }
        cFeatureDelegation anonymousAuthentication 
        {
            SectionName      = "security/authentication/anonymousAuthentication"
            OverrideMode   = "Allow"
        }    
        
        cFeatureDelegation ipSecurity 
        {
            SectionName      = "security/ipSecurity"
            OverrideMode   = "Allow"
        }       
        
        # "httpErrors"
        # "security/access"
        # "security/authentication/windowsAuthentication"
        # "security/authentication/anonymousAuthentication"
        # "security/ipSecurity"
        # "serverRuntime"
    }
}