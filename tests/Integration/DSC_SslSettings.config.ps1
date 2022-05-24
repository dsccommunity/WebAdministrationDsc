#requires -Version 4

configuration DSC_SslSettings_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        xSslSettings Website
        {
            Ensure = 'Present'
            Name = $Node.Website
            Bindings = $Node.Bindings
        }
    }
}

configuration DSC_SslSettings_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {
        xSslSettings Website
        {
            Ensure = 'Absent'
            Name = $Node.Website
            Bindings = ''
        }
    }
}
