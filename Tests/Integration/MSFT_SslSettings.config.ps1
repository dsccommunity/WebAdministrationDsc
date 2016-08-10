#requires -Version 4

configuration MSFT_SslSettings_Present
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName
    {  
        SslSettings Website
        {
            Ensure = 'Present'
            Name = $Node.Website
            Bindings = $Node.Bindings
        }
    }
}

configuration MSFT_SslSettings_Absent
{
    Import-DscResource -ModuleName WebAdministrationDsc

    Node $AllNodes.NodeName 
    {  
        SslSettings Website
        {
            Ensure = 'Absent'
            Name = $Node.Website
            Bindings = ''
        }
    }
}
