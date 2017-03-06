Configuration MSFT_xIISRemoteManagement_Enabled 
{
    Import-DscResource -ModuleName xWebAdministration

    xIISRemoteManagement InstallRemoteManagement
    {
        Ensure = 'Present'
        State  = 'Started'
        WindowsCredential = $true
    }
}

Configuration MSFT_xIISRemoteManagement_Disabled 
{
    Import-DscResource -ModuleName xWebAdministration

    xIISRemoteManagement UninstallRemoteManagement
    {
        Ensure = 'Absent'
        State  = 'Stopped'
    }
}
