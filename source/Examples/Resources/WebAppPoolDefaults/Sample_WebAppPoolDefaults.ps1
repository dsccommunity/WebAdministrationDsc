<#
    .SYNOPSIS
        An example of configuring the application pool default settings.
    .DESCRIPTION
        This examples show how to use WebAppPoolDefaults for configuring the application pool default settings.
        The resource is currently limited to configuring the managed runtime version and the identity used for the application pools.
#>
Configuration Sample_WebAppPoolDefaults
{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module WebAdministrationDsc, PSDesiredStateConfiguration

    Node $NodeName
    {
        # Configures the application pool defaults.
        WebAppPoolDefaults PoolDefaults
        {
            IsSingleInstance      = 'Yes'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType          = 'ApplicationPoolIdentity'
        }
    }
}
