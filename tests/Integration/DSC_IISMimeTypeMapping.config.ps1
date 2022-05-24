configuration DSC_xIISMimeTypeMapping_AddMimeType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping AddMimeType2
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Present'
    }
}

configuration DSC_xIISMimeTypeMapping_RemoveMimeType
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping RemoveMimeType
    {
        ConfigurationPath = ''
        Extension = $ConfigurationData.NonNodeData.FileExtension
        MimeType  = $ConfigurationData.NonNodeData.MimeType
        Ensure    = 'Absent'
    }
}

Configuration DSC_xIISMimeTypeMapping_AddMimeTypeNestedPath
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping AddMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration DSC_xIISMimeTypeMapping_RemoveMimeTypeNestedPath
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping RemoveMimeTypeNestedPath
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.VirtualConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}

Configuration DSC_xIISMimeTypeMapping_AddMimeTypeAtServer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Present'
    }
}

Configuration DSC_xIISMimeTypeMapping_RemoveMimeTypeAtServer
{
    Import-DscResource -ModuleName WebAdministrationDsc

    xIISMimeTypeMapping AddMimeTypeAtServer
    {
        ConfigurationPath = $ConfigurationData.NonNodeData.ServerConfigurationPath
        Extension         = $ConfigurationData.NonNodeData.FileExtension
        MimeType          = $ConfigurationData.NonNodeData.MimeType
        Ensure            = 'Absent'
    }
}
