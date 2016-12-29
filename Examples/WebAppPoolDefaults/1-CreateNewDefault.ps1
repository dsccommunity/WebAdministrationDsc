<#
    .EXAMPLE
    This example shows how to create a default for an App Pool
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
         xWebAppPoolDefaults PoolDefaults
         {
            ApplyTo = 'Machine'
            ManagedRuntimeVersion = 'v4.0'
            IdentityType = 'ApplicationPoolIdentity'
         }
    }
}
