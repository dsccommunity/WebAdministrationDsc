<#
    .EXAMPLE
    This example shows how to configure a new website on a node with SSL Flags on the website
#>

configuration Example
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
        # Create the new Website
        # Have it set to the CertificateThumbprint
        # and set that the Server Name Indication is required
        xWebsite NewWebsite
        {
            Ensure          = "Present"
            Name            = 'contoso.com'
            State           = "Started"
            PhysicalPath    = 'C:\wwwroot'
            BindingInfo     = MSFT_xWebBindingInformation
            {
                Protocol              = 'https'
                Port                  = '443'
                CertificateStoreName  = 'MY'
                CertificateThumbprint = 'BB84DE3EC423DDDE90C08AB3C5A828692089493C'
                HostName              = 'contoso.com'
                IPAddress             = '*'
                SSLFlags              = '1'
            }
        }
    }
}
