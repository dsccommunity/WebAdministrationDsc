#requires -Version 4

configuration MSFT_xSslSettings_Present
{
    Import-DscResource -ModuleName xWebAdministration

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

configuration MSFT_xSslSettings_Absent
{
    Import-DscResource -ModuleName xWebAdministration

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
