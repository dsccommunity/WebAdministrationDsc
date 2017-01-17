{
    param
    (
        # Target nodes to apply the configuration
        [string[]]$NodeName = 'localhost'
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xWebAdministration

    Node $NodeName
    {
        xIisRemoteManagement IisRM
        {
            Ensure = 'Present'
            Status = 'Enabled'
        }
    }
}
