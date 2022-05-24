[string] $originalValue = (Get-WebConfigurationProperty `
    -PSPath 'MACHINE/WEBROOT/APPHOST' `
    -Filter 'system.applicationHost/sites/virtualDirectoryDefaults' `
    -Name 'allowSubDirConfig').Value

if ($originalValue -eq "true")
{
    $env:PesterVirtualDirectoryDefaults = "false"
}
else
{
    $env:PesterVirtualDirectoryDefaults = "true"
}

configuration DSC_WebSiteDefaults_Config
{
    Import-DscResource -ModuleName WebAdministrationDsc

    WebSiteDefaults virtualDirectoryDefaults
    {
        IsSingleInstance = 'Yes'
        AllowSubDirConfig = "$env:PesterVirtualDirectoryDefaults"
    }
}
