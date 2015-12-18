configuration MSFT_xWebsiteDefaults_Config
{
    Import-DscResource -ModuleName xWebAdministration

    xWebSiteDefaults virtualDirectoryDefaults
    {
        ApplyTo = 'Machine'
        AllowSubDirConfig = "$env:PesterVirtualDirectoryDefaults"
    }
}
