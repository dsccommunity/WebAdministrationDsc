<#
.SYNOPSIS
    Create a new web application on the Default Web Site
.DESCRIPTION
    This example shows how to use the xWebApplication DSC resource to create a new web application.
#>
Configuration Example
{
    param
    (
        # Target nodes to apply the configuration
        [String[]] $NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        # Create a new application pool for the application
        xWebAppPool SampleAppPool
        {
            Ensure                  = 'Present'
            Name                    = 'SampleAppPool'
        }

        # Create a new web application with Windows Authentication
        xWebApplication SampleApplication 
        {
            Ensure                  = 'Present'
            Name                    = 'SampleApplication'
            WebAppPool              = 'SampleAppPool'
            Website                 = 'Default Web Site'
            PreloadEnabled          = $true
            ServiceAutoStartEnabled = $true
            AuthenticationInfo      = MSFT_xWebApplicationAuthenticationInformation
            {
                Anonymous   = $false
                Basic       = $false
                Digest      = $false
                Windows     = $true
            }
            SslFlags                = ''
            PhysicalPath            = 'C:\webroot'
            DependsOn               = '[xWebAppPool]SampleAppPool'
        }
    }
}

